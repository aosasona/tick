import gleam/dynamic.{type Decoder}
import gleam/result
import gleam/option.{type Option, None, Some}
import dot_env/env
import sqlight
import tick/api.{type ErrorResponse, DatabaseError}

fn get_db_path() -> String {
  env.get("DB_PATH")
  |> result.unwrap("data.db")
}

pub fn connect() -> sqlight.Connection {
  let assert Ok(db) = sqlight.open("file:" <> get_db_path())
  let assert Ok(_) = sqlight.exec("PRAGMA foreign_keys = ON;", db)
  db
}

pub fn query_one(
  conn conn: sqlight.Connection,
  query query: String,
  params params: List(sqlight.Value),
  expecting decoder: Decoder(a),
) -> Result(Option(a), ErrorResponse) {
  let query_result =
    sqlight.query(query, on: conn, with: params, expecting: decoder)
    |> result.map_error(DatabaseError)

  case query_result {
    Ok([row]) | Ok([row, ..]) -> Ok(Some(row))
    Ok([]) -> Ok(None)
    Error(e) -> Error(e)
  }
}

pub fn query_many(
  conn conn: sqlight.Connection,
  query query: String,
  params params: List(sqlight.Value),
  expecting decoder: Decoder(a),
) -> Result(List(a), ErrorResponse) {
  let query_result =
    sqlight.query(query, on: conn, with: params, expecting: decoder)
    |> result.map_error(DatabaseError)

  case query_result {
    Ok(d) -> Ok(d)
    Error(e) -> Error(e)
  }
}

pub fn execute(
  conn conn: sqlight.Connection,
  query query: String,
) -> Result(Nil, ErrorResponse) {
  sqlight.exec(query, conn)
  |> result.map_error(DatabaseError)
}
