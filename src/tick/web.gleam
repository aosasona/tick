import gleam/option.{type Option}
import sqlight.{type Connection}
import wisp

pub const auth_token_key = "auth_token"

pub type Context {
  Context(database: Connection, web_directory: String)
}

pub fn set_cookie(
  request request: wisp.Request,
  key key: String,
  value value: String,
  ttl max_age: Int,
) {
  wisp.set_cookie(
    response: wisp.response(200),
    request: request,
    name: key,
    value: value,
    security: wisp.Signed,
    max_age: max_age,
  )
}

pub fn remove_cookie(request request: wisp.Request, key key: String) {
  wisp.set_cookie(
    response: wisp.response(200),
    request: request,
    name: key,
    value: "",
    security: wisp.Signed,
    max_age: 0,
  )
}

pub fn get_cookie(
  request request: wisp.Request,
  key key: String,
) -> Option(String) {
  request
  |> wisp.get_cookie(key, wisp.Signed)
  |> option.from_result
}
