import wisp
import gleam/string_builder
import gleam/string
import gleam/json.{type Json}
import sqlight

pub type SuccessResponse {
  Created(json.Json)
  Data(json: Json)
  EmptySuccess
  HealthCheck
}

pub type ErrorResponse {
  ClientError(message: String, code: Int)
  DatabaseError(sqlight.Error)
  NotFound
}

type ApiError {
  ApiError(message: String, code: Int, errors: List(#(String, Json)))
}

type ApiSuccess {
  ApiSuccess(message: String, code: Int, data: Json)
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
  let ApiSuccess(message, code, data) = case response {
    Created(data) -> ApiSuccess("Resource created", 201, data)
    Data(data) -> ApiSuccess("Success", 200, data)
    EmptySuccess -> ApiSuccess("Success", 200, json.null())
    HealthCheck -> ApiSuccess("I am alive", 200, json.null())
  }

  message
  |> string.lowercase
  |> make_success_json(data)
  |> string_builder.from_string
  |> wisp.json_response(code)
}

fn make_success_json(message: String, data: Json) -> String {
  let res = [#("message", json.string(message)), #("ok", json.bool(True))]

  json.object(case json.to_string(data) {
    "null" -> res
    _ -> [#("data", data), ..res]
  })
  |> json.to_string
}

fn handle_error_response(response: ErrorResponse) -> wisp.Response {
  let ApiError(message, code, errors) = case response {
    ClientError(message, code) -> ApiError(message, code, [])
    DatabaseError(e) -> {
      wisp.log_error(e.message)
      ApiError("Something went wrong. Please try again later.", 500, [])
    }
    NotFound -> ApiError("Not found", 404, [])
  }

  message
  |> string.lowercase
  |> make_error_json(errors)
  |> string_builder.from_string
  |> wisp.json_response(code)
}

fn make_error_json(message: String, errors: List(#(String, Json))) -> String {
  let res = [#("error", json.string(message)), #("ok", json.bool(False))]

  json.object(case errors {
    [] -> res
    _ -> [#("errors", json.array(errors, errors_json)), ..res]
  })
  |> json.to_string
}

fn errors_json(err: #(String, Json)) {
  json.object([#(err.0, err.1)])
}
