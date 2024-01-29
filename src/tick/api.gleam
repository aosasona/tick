import birl.{to_unix, utc_now}
import crossbar
import gleam/bool
import gleam/dynamic
import gleam/list
import gleam/string_builder
import gleam/io
import gleam/http.{type Method}
import gleam/http/response.{Response as HttpResponse}
import gleam/json.{type Json}
import gleam/result
import sqlight
import wisp

pub type SuccessResponse {
  Created(json.Json)
  Data(json: Json)
  DataWithMessage(json: Json, message: String)
  /// This is a special case for when we have a response already created and we want to append data onto it
  DataWithResponse(json: Json, response: wisp.Response)
  EmptySuccess
  HealthCheck
  Pong
}

pub type ErrorResponse {
  ClientError(message: String, code: Int)
  DatabaseError(sqlight.Error)
  DecodeError(List(dynamic.DecodeError))
  InvalidJson(json.DecodeError)
  NotAuthenticated
  NotAuthorized
  NotFound
  ServerError(message: String, code: Int)
  InvalidBodyType(wisp.Response)
  ValidationErrors(List(#(String, List(crossbar.CrossBarError))))
}

type ApiError {
  ApiError(message: String, code: Int, errors: List(#(String, Json)))
}

type ApiSuccess {
  ApiSuccess(
    message: String,
    code: Int,
    data: Json,
    headers: List(#(String, String)),
  )
}

pub type ApiResponse =
  Result(SuccessResponse, ErrorResponse)

pub fn to_response(response: ApiResponse) -> wisp.Response {
  case response {
    Ok(res) -> handle_success_response(res)
    Error(res) -> handle_error_response(res)
  }
}

pub fn require_method(
  request: wisp.Request,
  method: Method,
  next: fn() -> ApiResponse,
) -> ApiResponse {
  use <- bool.guard(request.method == method, next())
  Error(ClientError("Method not allowed", 405))
}

pub fn json_body(
  request request: wisp.Request,
  decoder decode: dynamic.Decoder(a),
  next next: fn(a) -> ApiResponse,
) -> ApiResponse {
  // We are returning responses differently but the wisp.require_json function will only return a response, so we need to trap that response while still also getting the raw (dynamic) json body out of there
  let wrapped_res = {
    use <- wisp.require_content_type(request, "application/json")
    use body <- wisp.require_string_body(request)

    body
    |> wisp.string_body(wisp.response(200), _)
  }

  let HttpResponse(status, _, string_body) = wrapped_res
  use <- bool.guard(status != 200, Error(InvalidBodyType(wrapped_res)))

  case string_body {
    wisp.Text(sb_body) -> {
      let body = string_builder.to_string(sb_body)

      use decoded_json <- result.try(
        json.decode(body, decode)
        |> result.map_error(InvalidJson),
      )

      next(decoded_json)
    }
    _ -> Error(InvalidBodyType(wrapped_res))
  }
}

fn handle_success_response(response: SuccessResponse) -> wisp.Response {
  let ApiSuccess(message, code, data, headers) = case response {
    Created(data) ->
      ApiSuccess("Resource created", code: 201, data: data, headers: [])

    Data(data) ->
      ApiSuccess("Request successful", code: 200, data: data, headers: [])

    DataWithMessage(data, message) ->
      ApiSuccess(message, code: 200, data: data, headers: [])

    DataWithResponse(data, addtional_response) -> {
      let HttpResponse(_, headers, _) = addtional_response
      ApiSuccess("Request successful", code: 200, data: data, headers: headers)
    }

    EmptySuccess ->
      ApiSuccess("Success", code: 200, data: json.null(), headers: [])

    HealthCheck ->
      ApiSuccess("I am alive", code: 200, data: json.null(), headers: [])

    Pong ->
      ApiSuccess(
        "Pong",
        code: 200,
        data: json.object([#("current_time", json.int(to_unix(utc_now())))]),
        headers: [],
      )
  }

  message
  |> make_success_json(data)
  |> string_builder.from_string
  |> wisp.json_response(code)
  |> append_headers(headers)
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

    DecodeError(errors) -> {
      io.debug(errors)

      ApiError("Bad request", 400, [])
    }

    InvalidJson(e) -> {
      e
      |> fn(e) {
        case e {
          json.UnexpectedEndOfInput -> "Unexpected end of input"
          json.UnexpectedByte(byte, _) -> "Unexpected byte: " <> byte
          json.UnexpectedSequence(byte, _) -> "Unexpected sequence: " <> byte
          json.UnexpectedFormat(_) -> "Unexpected format"
        }
      }
      |> fn(m) { wisp.log_error("Failed to decode JSON: " <> m) }

      ApiError("Invalid JSON body received", 400, [])
    }

    InvalidBodyType(_) -> ApiError("Unsupported payload type", 415, [])

    NotAuthenticated ->
      ApiError("You must be logged in to perform this action!", 401, [])

    NotAuthorized ->
      ApiError("You are not authorized to perform this action!", 403, [])

    NotFound -> ApiError("Not found", 404, [])

    ServerError(message, code) -> {
      wisp.log_error(message)

      let code = case code {
        x if x >= 500 -> x
        _ -> 500
      }
      ApiError("Internal server error, please retry in a few minutes", code, [])
    }

    ValidationErrors(errors) ->
      errors
      |> crossbar.to_serializable_list(crossbar.Array)
      |> ApiError("Bad request", 400, _)
  }

  message
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

fn append_headers(
  response: wisp.Response,
  headers: List(#(String, String)),
) -> wisp.Response {
  case headers {
    [] -> response
    _ -> {
      HttpResponse(
        status: response.status,
        body: response.body,
        headers: list.concat([response.headers, headers]),
      )
    }
  }
}
