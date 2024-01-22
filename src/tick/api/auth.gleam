import tick/api.{type ApiResponse}
import tick/web.{type Context}
import wisp.{type Request}

pub fn sign_in(req: Request, ctx: Context) -> ApiResponse {
  Ok(api.EmptySuccess)
}

pub fn sign_up(req: Request, ctx: Context) -> ApiResponse {
  Ok(api.EmptySuccess)
}
