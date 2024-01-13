import gleam/http.{Get, Post}
import gleam/http/request
import gleam/io
import gleam/string_builder
import wisp
import simplifile
import tick/api
import tick/api/auth
import tick/web

pub fn handle_request(req: wisp.Request, ctx: web.Context) -> wisp.Response {
  use <- wisp.serve_static(req, "/assets", ctx.web_directory <> "/assets")

  case req.method, request.path_segments(req) {
    _, ["api", ..path] ->
      handle_api_routes(req, ctx, path)
      |> api.to_response
    _, _ -> serve_ui(ctx.web_directory)
  }
}

fn handle_api_routes(
  req: wisp.Request,
  ctx: web.Context,
  path_parts: List(String),
) -> api.Response {
  case req.method, path_parts {
    Get, ["health"] -> Ok(api.HealthCheck)
    Post, ["auth", "sign-in"] -> auth.sign_in(req, ctx)
    _, _ -> Error(api.NotFound)
  }
}

fn serve_ui(web_directory: String) {
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
