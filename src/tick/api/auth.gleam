import crossbar.{string_value}
import gleam/bool
import gleam/dynamic
import gleam/http.{Get, Post}
import gleam/json
import gleam/list
import gleam/option.{type Option, None}
import gleam/result.{try}
import tick/models/user.{type User, User}
import tick/models/auth_token
import tick/api.{
  type ApiResponse, type ErrorResponse, ClientError, Data, DataWithResponse,
  NotAuthenticated, ServerError, ValidationErrors,
}
import tick/web.{type Context}
import wisp.{type Request}

const auth_token_key = "auth_token"

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
  use opt_user <- result.try(user.find_by_email(ctx.database, body.email))
  use user <- try(
    opt_user
    |> option.to_result(ClientError("Invalid email or password", 401)),
  )
  use <- bool.guard(
    when: !user.verify_password(body.password, user.password),
    return: Error(ClientError("Invalid email or password", 401)),
  )
  use token <- try(auth_token.new(ctx.database, user.id))

  web.set_cookie(req, auth_token_key, token.value, token.ttl_in_seconds)
  |> DataWithResponse(user.to_json(user), _)
  |> Ok()
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
  |> DataWithResponse(json.null(), _)
  |> Ok()
}

pub fn me(req: Request, ctx: Context) -> ApiResponse {
  use <- api.require_method(req, Get)
  use token <- try(
    web.get_cookie(req, auth_token_key)
    |> option.to_result(NotAuthenticated),
  )
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
