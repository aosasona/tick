import gleam/dynamic.{type Decoder}
import gleam/json
import gleam/option.{type Option}
import gleam/result.{try}
import ids/nanoid
import sqlight.{int, text}
import tick/api.{type ErrorResponse}
import tick/database.{query_one}

const default_ttl: Int = 2_592_000

pub type AuthToken {
  AuthToken(
    id: Int,
    user_id: Int,
    value: String,
    ttl_in_seconds: Int,
    issued_at: Int,
  )
}

pub fn new(conn, user_id: Option(Int)) -> Result(AuthToken, ErrorResponse) {
  use uid <- try(option.to_result(
    user_id,
    api.ServerError("Missing user_id", 500),
  ))

  let token_str = nanoid.generate() <> nanoid.generate()
  let query =
    "insert into auth_tokens (user_id, token, ttl_in_seconds) values (?, ?, ?) returning *"

  use created_token <- try(query_one(
    conn: conn,
    query: query,
    params: [int(uid), text(token_str), int(default_ttl)],
    expecting: db_decoder(),
  ))

  created_token
  |> option.to_result(api.ServerError("Failed to create token", 500))
}

pub fn to_json(token: AuthToken) -> json.Json {
  json.object([
    #("user_id", json.int(token.user_id)),
    #("value", json.string(token.value)),
    #("issued_at", json.int(token.issued_at)),
    #("expires_at", json.int(token.ttl_in_seconds + token.issued_at)),
  ])
}

pub fn decoder() -> Decoder(AuthToken) {
  dynamic.decode5(
    AuthToken,
    dynamic.field("id", dynamic.int),
    dynamic.field("user_id", dynamic.int),
    dynamic.field("token", dynamic.string),
    dynamic.field("ttl", dynamic.int),
    dynamic.field("issued_at", dynamic.int),
  )
}

fn db_decoder() -> Decoder(AuthToken) {
  dynamic.decode5(
    AuthToken,
    dynamic.element(0, dynamic.int),
    dynamic.element(1, dynamic.int),
    dynamic.element(2, dynamic.string),
    dynamic.element(3, dynamic.int),
    dynamic.element(4, dynamic.int),
  )
}
