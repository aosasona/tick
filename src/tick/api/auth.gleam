import tick/api.{type Response}
import tick/web.{type Context}
import wisp.{type Request}

pub fn sign_in(req: Request, ctx: web.Context) -> api.Response {
  Ok(api.EmptySuccess)
}

pub fn sign_up(req: Request, ctx: web.Context) -> api.Response {
  Ok(api.EmptySuccess)
}
