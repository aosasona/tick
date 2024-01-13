import gleam/result
import dot_env/env
import sqlight

fn get_db_path() -> String {
  env.get("DB_PATH")
  |> result.unwrap("data.db")
}

pub fn connect() -> sqlight.Connection {
  let assert Ok(db) = sqlight.open("file:" <> get_db_path())
  let assert Ok(_) = sqlight.exec("PRAGMA foreign_keys = ON;", db)
  db
}

// TODO: implement
pub fn migrate() {
  Nil
}
