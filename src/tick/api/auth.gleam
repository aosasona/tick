import crossbar
import gleam/bool
import gleam/dynamic
import gleam/list
import gleam/io
import gleam/regex
import gleam/result
import tick/api.{
  type ApiResponse, type ErrorResponse, ServerError, ValidationErrors,
}
import tick/web.{type Context}
import wisp.{type Request}

type CreateUserPayload {
  CreateUserPayload(email: String, password: String, confirm_password: String)
}

pub fn sign_in(_req: Request, _ctx: Context) -> ApiResponse {
  Ok(api.EmptySuccess)
}

pub fn sign_up(req: Request, _ctx: Context) -> ApiResponse {
  use user <- api.json_body(req, create_user_payload_decoder())
  use user <- result.try(validate_create_user_payload(user))

  io.debug(user)

  Ok(api.EmptySuccess)
}

fn create_user_payload_decoder() -> dynamic.Decoder(CreateUserPayload) {
  dynamic.decode3(
    CreateUserPayload,
    dynamic.field("email", dynamic.string),
    dynamic.field("password", dynamic.string),
    dynamic.field("confirm_password", dynamic.string),
  )
}

fn validate_create_user_payload(
  user: CreateUserPayload,
) -> Result(CreateUserPayload, ErrorResponse) {
  // TODO: move these regexes to a module level function
  use email_regex <- result.try(
    regex.from_string("\\b[a-z0-9._%+-]+@[a-z0-9.-]+\\.[a-z]{2,4}\\b")
    |> result.map_error(fn(e) {
      ServerError("Failed to compile email regex: " <> e.error)
    }),
  )

  // TODO: update
  use password_regex <- result.try(
    regex.from_string(
      "/^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^&*-])$/",
    )
    |> result.map_error(fn(e) {
      ServerError("Failed to compile password regex: " <> e.error)
    }),
  )

  let email =
    user.email
    |> crossbar.string("email", _)
    |> crossbar.required
    |> crossbar.regex(
      "valid_email",
      email_regex,
      "must be a valid email address",
    )

  let password =
    user.password
    |> wisp.escape_html
    |> crossbar.string("password", _)
    |> crossbar.required
    |> crossbar.min_length(8)
    |> crossbar.regex(
      "valid_password",
      password_regex,
      "must only contain letters, numbers, and special characters",
    )

  let confirm_password =
    user.confirm_password
    |> wisp.escape_html
    |> crossbar.string("confirm_password", _)
    |> crossbar.required
    |> crossbar.min_length(8)
    |> crossbar.eq("password", user.password)

  let errors =
    crossbar.validate_many(
      fields: [email, password, confirm_password],
      keep_failed_only: True,
    )

  use <- bool.guard(!list.is_empty(errors), Error(ValidationErrors(errors)))

  Ok(user)
}
