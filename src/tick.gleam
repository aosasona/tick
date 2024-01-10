import dot_env
import dot_env/env
import gleam/io
import gleam/int
import gleam/result

pub fn main() {
  dot_env.load()

  let port =
    env.get_int("PORT")
    |> result.unwrap(9000)

  io.println("Starting server on port: " <> int.to_string(port))
}
