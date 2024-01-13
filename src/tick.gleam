import dot_env
import dot_env/env
import gleam/erlang/process
import gleam/result
import migrant
import mist
import tick/database
import tick/web
import tick/router
import wisp

pub fn main() {
  wisp.configure_logger()
  dot_env.load()

  let port = get_port()
  let db = database.connect()

  let assert Ok(priv) = wisp.priv_directory("tick")
  let web_directory = priv <> "/web"
  let assert Ok(_) = migrant.migrate(db, priv <> "/migrations")

  let ctx = web.Context(database: db, web_directory: web_directory)

  // TODO: start with OTP
  let assert Ok(_) =
    router.handle_request(_, ctx)
    |> wisp.mist_handler(get_secret_key())
    |> mist.new
    |> mist.port(port)
    |> mist.start_http

  process.sleep_forever()
}

fn get_secret_key() -> String {
  env.get("SECRET_KEY")
  |> result.unwrap("secret")
}

fn get_port() -> Int {
  env.get_int("PORT")
  |> result.unwrap(9000)
}
