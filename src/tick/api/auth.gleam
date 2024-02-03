import crossbar.{string_value}
import gleam/bool
import gleam/dynamic
import gleam/http.{Get, Post}
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{type Option, None}
import gleam/result.{try}
import tick/models/user.{type User, User}
import tick/models/auth_token
import tick/models/login_attempt.{
  RateLimitCheck, can_attempt_login, make_rate_limit_response,
  save_failed_login_attempt,
}
import tick/api.{
  type ApiResponse, type ErrorResponse, ClientError, Data, ErrorWithResponse,
  NotAuthenticated, ServerError, SuccessWithResponse, ValidationErrors,
}
import tick/web.{type Context, auth_token_key}
import wisp.{type Request}

// Using optional fields so that decoding doesn't fail if the field is missing and it can be caught by validation
type CreateUserPayload {
  CreateUserPayload(
    email: Option(String),
    password: Option(String),
    confirm_password: Option(String),
  )
}

type SignInPayload {
  SignInPayload(email: Option(String), password: Option(String))
}

pub fn sign_in(req: Request, ctx: Context) -> ApiResponse {
  use <- api.require_method(req, Post)
  use body <- api.json_body(req, sign_in_payload_decoder())
  use body <- try(validate_sign_in_payload(body))
  use opt_user <- try(user.find_by_email(ctx.database, body.email))

  use user <- try(
    opt_user
    |> option.to_result(ClientError("Invalid email or password", 401)),
  )

  use limit <- try(can_attempt_login(ctx.database, user.id))
  use <- bool.guard(
    when: !limit.can_attempt,
    return: Error(ErrorWithResponse(
      ClientError("Too many login attempts", 429),
      make_rate_limit_response(limit),
    )),
  )

  use <- bool.guard(
    when: !user.verify_password(body.password, user.password),
    return: {
      use _ <- try(save_failed_login_attempt(ctx.database, user.id))

      // Append the proper rate limit headers to the response
      let new_limit =
        RateLimitCheck(
          ..limit,
          attempts_remaining: limit.attempts_remaining
          - 1,
        )

      Error(ErrorWithResponse(
        ClientError("Invalid email or password", 401),
        make_rate_limit_response(new_limit),
      ))
    },
  )

  use token <- try(auth_token.new(ctx.database, user.id))
  let cookie =
    web.set_cookie(req, auth_token_key, token.value, token.ttl_in_seconds)

  Ok(SuccessWithResponse(Data(user.to_json(user)), cookie))
}

pub fn sign_up(req: Request, ctx: Context) -> ApiResponse {
  use <- api.require_method(req, Post)
  use body <- api.json_body(req, create_user_payload_decoder())
  use body <- result.try(validate_create_user_payload(body))
  use opt_user <- result.try(user.find_by_email(ctx.database, body.email))
  use <- bool.guard(
    option.is_some(opt_user),
    Error(ClientError("A user with this email already exists", 409)),
  )
  use created_user <- result.try(user.create(ctx.database, body))
  use u <- result.try(
    created_user
    |> option.to_result(ServerError("Failed to create user, got none back", 500)),
  )

  Ok(Data(user.to_json(u)))
}

pub fn sign_out(req: Request, ctx: Context) -> ApiResponse {
  use <- api.require_method(req, Post)
  use token <- try(
    web.get_cookie(req, auth_token_key)
    |> option.to_result(NotAuthenticated),
  )
  use _ <- try(auth_token.delete(ctx.database, token))

  web.remove_cookie(req, auth_token_key)
  |> SuccessWithResponse(Data(json.null()), _)
  |> Ok()
}

pub fn me(req: Request, ctx: Context) -> ApiResponse {
  use <- api.require_method(req, Get)
  use token <- api.require_auth(req, ctx.database)
  use opt_user <- try(auth_token.find_user(ctx.database, token))
  use user <- try(option.to_result(opt_user, NotAuthenticated))

  Ok(Data(user.to_json(user)))
}

fn create_user_payload_decoder() -> dynamic.Decoder(CreateUserPayload) {
  dynamic.decode3(
    CreateUserPayload,
    dynamic.optional_field("email", dynamic.string),
    dynamic.optional_field("password", dynamic.string),
    dynamic.optional_field("confirm_password", dynamic.string),
  )
}

fn sign_in_payload_decoder() -> dynamic.Decoder(SignInPayload) {
  dynamic.decode2(
    SignInPayload,
    dynamic.optional_field("email", dynamic.string),
    dynamic.optional_field("password", dynamic.string),
  )
}

fn validate_sign_in_payload(
  payload: SignInPayload,
) -> Result(User, ErrorResponse) {
  use email_regex <- user.email_regex()

  let email =
    payload.email
    |> option.unwrap("")
    |> crossbar.string("email", _)
    |> crossbar.required
    |> crossbar.regex(
      "valid_email",
      email_regex,
      "must be a valid email address",
    )

  let password =
    payload.password
    |> option.unwrap("")
    |> wisp.escape_html
    |> crossbar.string("password", _)
    |> crossbar.required
    |> crossbar.min_length(8)

  let errors =
    crossbar.validate_many(fields: [email, password], keep_failed_only: True)

  use <- bool.guard(list.length(errors) > 0, Error(ValidationErrors(errors)))
  Ok(User(
    id: None,
    email: string_value(email),
    password: string_value(password),
    created_at: None,
  ))
}

fn validate_create_user_payload(
  user: CreateUserPayload,
) -> Result(User, ErrorResponse) {
  use email_regex <- user.email_regex()

  let email =
    user.email
    |> option.unwrap("")
    |> crossbar.string("email", _)
    |> crossbar.required
    |> crossbar.regex(
      "valid_email",
      email_regex,
      "must be a valid email address",
    )

  let password =
    user.password
    |> option.unwrap("")
    |> wisp.escape_html
    |> crossbar.string("password", _)
    |> crossbar.required
    |> crossbar.min_length(8)

  let confirm_password =
    user.confirm_password
    |> option.unwrap("")
    |> wisp.escape_html
    |> crossbar.string("confirm_password", _)
    |> crossbar.required
    |> crossbar.min_length(8)
    |> crossbar.eq(
      "password",
      password
      |> crossbar.string_value,
    )

  let errors =
    crossbar.validate_many(
      fields: [email, password, confirm_password],
      keep_failed_only: True,
    )

  use <- bool.guard(list.length(errors) > 0, Error(ValidationErrors(errors)))
  Ok(User(
    id: None,
    email: string_value(email),
    password: string_value(password),
    created_at: None,
  ))
}
