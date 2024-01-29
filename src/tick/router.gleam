import gleam/http/request
import gleam/io
import gleam/string_builder
import simplifile
import tick/api.{type ApiResponse}
import tick/api/auth
import tick/web
import wisp

pub fn handle_request(req: wisp.Request, ctx: web.Context) -> wisp.Response {
  use <- wisp.serve_static(req, "/assets", ctx.web_directory <> "/assets")

  case request.path_segments(req) {
    ["api", ..path] ->
      handle_api_routes(req, ctx, path)
      |> api.to_response
    _ -> serve_ui(ctx.web_directory)
  }
}

fn handle_api_routes(
  req: wisp.Request,
  ctx: web.Context,
  path_parts: List(String),
) -> ApiResponse {
  case path_parts {
    ["health"] -> Ok(api.HealthCheck)
    ["auth", "sign-in"] -> auth.sign_in(req, ctx)
    ["auth", "sign-up"] -> auth.sign_up(req, ctx)
    ["auth", "sign-out"] -> auth.sign_out(req, ctx)
    ["me"] -> auth.me(req, ctx)
    ["ping"] -> Ok(api.Pong)
    _ -> Error(api.NotFound)
  }
}

fn serve_ui(web_directory: String) -> wisp.Response {
  case simplifile.read(from: web_directory <> "/index.html") {
    Ok(html) ->
      html
      |> string_builder.from_string
      |> wisp.html_response(200)

    Error(e) -> {
      case e {
        simplifile.Enoent -> wisp.not_found()
        _ -> {
          io.debug(e)
          wisp.internal_server_error()
        }
      }
    }
  }
}
