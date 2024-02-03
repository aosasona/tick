import birl
import gleam/bool
import gleam/dynamic.{type Decoder}
import gleam/option.{type Option, None, Some}
import gleam/http/response.{Response as HttpResponse}
import gleam/int.{to_string}
import gleam/result
import gleam/string
import sqlight.{type Connection}
import tick/api.{type ErrorResponse}
import tick/database
import wisp

// The number of seconds to look back for failed login attempts
pub const retry_window = 3600

// The maximum number of failed login attempts before the account is temporarily locked for the retry window
pub const max_attempts = 5

pub type Status {
  Success
  Failure
}

pub type LoginAttempt {
  LoginAttempt(id: Int, user_id: Int, status: Status, attempted_at: Int)
}

pub type RateLimitCheck {
  RateLimitCheck(resets_at: Int, attempts_remaining: Int, can_attempt: Bool)
}

pub fn save_failed_login_attempt(
  conn: Connection,
  user_id user_id: Option(Int),
) -> Result(Option(LoginAttempt), ErrorResponse) {
  use uid <- result.try(option.to_result(
    user_id,
    api.ServerError("Missing user_id while saving failed login attempt", 500),
  ))

  let query =
    "insert into `login_attempts` (`user_id`, `status`) values (?, ?) returning *"

  database.query_one(
    conn: conn,
    query: query,
    params: [sqlight.int(uid), sqlight.text("failure")],
    expecting: db_decoder(),
  )
}

pub fn can_attempt_login(
  conn: Connection,
  user_id user_id: Option(Int),
) -> Result(RateLimitCheck, ErrorResponse) {
  use uid <- result.try(option.to_result(
    user_id,
    api.ServerError(
      "Missing user_id while checking for failed login attempts",
      500,
    ),
  ))

  let now = birl.to_unix(birl.utc_now())
  let window_start = now - retry_window
  let query =
    "select count(id), COALESCE(min(attempted_at), 0) from `login_attempts` where `status` = 'failure' and `attempted_at` > ? and `user_id` = ?"

  use res <- result.try(database.query_one(
    conn: conn,
    query: query,
    params: [sqlight.int(window_start), sqlight.int(uid)],
    expecting: dynamic.tuple2(dynamic.int, dynamic.int),
  ))

  case res {
    Some(#(failed_attempts, first_failed_attempt)) ->
      Ok(
        RateLimitCheck(
          attempts_remaining: max_attempts - failed_attempts,
          can_attempt: failed_attempts < max_attempts,
          resets_at: {
            use <- bool.guard(
              when: first_failed_attempt > 0,
              return: first_failed_attempt + retry_window,
            )
            now + retry_window
          },
        ),
      )
    None ->
      Ok(RateLimitCheck(
        attempts_remaining: max_attempts,
        can_attempt: True,
        resets_at: now,
      ))
  }
}

pub fn make_rate_limit_response(check: RateLimitCheck) {
  HttpResponse(status: 429, body: wisp.Empty, headers: [
    #("x-rate-limit-limit", to_string(max_attempts)),
    #("x-rate-limit-remaining", to_string(check.attempts_remaining)),
    #("x-rate-limit-reset", to_string(check.resets_at)),
  ])
}

pub fn db_decoder() -> Decoder(LoginAttempt) {
  dynamic.decode4(
    LoginAttempt,
    dynamic.element(0, dynamic.int),
    dynamic.element(1, dynamic.int),
    dynamic.element(2, status_decoder),
    dynamic.element(3, dynamic.int),
  )
}

fn status_decoder(dyn: dynamic.Dynamic) -> Result(Status, dynamic.DecodeErrors) {
  use raw_status <- result.try(dynamic.string(dyn))

  case string.lowercase(raw_status) {
    "success" -> Ok(Success)
    "failure" -> Ok(Failure)
    _ -> Error([dynamic.DecodeError("guccess or failure", raw_status, [])])
  }
}
