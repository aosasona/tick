import wisp
import gleam/string_builder
import gleam/json.{type Json}
import sqlight

pub type SuccessResponse {
  Json(json: Json)
}

pub type ErrorResponse {
  ClientError(message: String, code: Int)
  DatabaseError(sqlight.Error)
}

type ApiError {
  ApiError(message: String, code: Int, errors: List(#(String, Json)))
}

pub type Response =
  Result(SuccessResponse, ErrorResponse)

pub fn to_response(response: Response) -> wisp.Response {
  case response {
    Ok(res) -> handle_success_response(res)
    Error(res) -> handle_error_response(res)
  }
}

fn handle_success_response(response: SuccessResponse) -> wisp.Response {
  todo
}

fn handle_error_response(response: ErrorResponse) -> wisp.Response {
  let ApiError(message, code, errors) = case response {
    ClientError(message, code) -> ApiError(message, code, [])
    DatabaseError(e) -> {
      wisp.log_error(e.message)
      ApiError("Something went wrong. Please try again later.", 500, [])
    }
  }

  message
  |> make_error_json(errors)
  |> string_builder.from_string
  |> wisp.json_response(code)
}

fn make_error_json(message: String, errors: List(#(String, Json))) -> String {
  json.object([
    #("error", json.string(message)),
    #("ok", json.bool(False)),
    #(
      "errors",
      json.array(errors, fn(error) { json.object([#(error.0, error.1)]) }),
    ),
  ])
  |> json.to_string
}
