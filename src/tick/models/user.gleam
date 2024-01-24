import gleam/dynamic.{type Decoder}
import gleam/json.{type Json}
import gleam/option.{type Option}
import gleam/regex.{type Regex}
import gleam/result
import sqlight.{type Connection}
import tick/database.{query_one}
import tick/api.{type ErrorResponse, ServerError}

pub type User {
  User(
    id: Option(Int),
    email: String,
    password: String,
    created_at: Option(Int),
  )
}

pub fn email_regex(next: fn(Regex) -> _) {
  use re <- result.try(
    regex.from_string("\\b[a-z0-9._%+-]+@[a-z0-9.-]+\\.[a-z]{2,4}\\b")
    |> result.map_error(fn(e) {
      ServerError("Failed to compile email regex: " <> e.error, 500)
    }),
  )

  next(re)
}

pub fn find_by_email(
  conn: Connection,
  email: String,
) -> Result(Option(User), ErrorResponse) {
  let query =
    "select id, email, password, unixepoch(created_at) from users where email = $1 limit 1"
  query_one(conn, query, [sqlight.text(email)], db_decoder())
}

pub fn create(
  conn: Connection,
  user: User,
) -> Result(Option(User), ErrorResponse) {
  let query =
    "insert into users (email, password) values ($1, $2) returning id, email, password, unixepoch(created_at)"
  let password = hash_password(user.password)
  query_one(
    conn: conn,
    query: query,
    params: [sqlight.text(user.email), sqlight.text(password)],
    expecting: db_decoder(),
  )
}

pub fn to_json(user: User) -> Json {
  json.object([
    #("id", json.nullable(user.id, of: json.int)),
    #("email", json.string(user.email)),
    #("created_at", json.nullable(user.created_at, of: json.int)),
  ])
}

fn db_decoder() -> Decoder(User) {
  dynamic.decode4(
    User,
    dynamic.element(0, dynamic.optional(dynamic.int)),
    dynamic.element(1, dynamic.string),
    dynamic.element(2, dynamic.string),
    dynamic.element(3, dynamic.optional(dynamic.int)),
  )
}

pub fn decoder() -> Decoder(User) {
  dynamic.decode4(
    User,
    dynamic.optional_field("id", dynamic.int),
    dynamic.field("email", dynamic.string),
    dynamic.field("password", dynamic.string),
    dynamic.optional_field("created_at", dynamic.int),
  )
}

pub fn hash_password(password: String) -> String {
  argon2_hash(password, [])
}

pub fn verify_password(password: String, hash: String) -> Bool {
  argon2_verify(password, hash)
}

@external(erlang, "Elixir.Argon2", "hash_pwd_salt")
fn argon2_hash(password: String, list: List(a)) -> String

@external(erlang, "Elixir.Argon2", "verify_pass")
fn argon2_verify(password: String, hash: String) -> Bool
