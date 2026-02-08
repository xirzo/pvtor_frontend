import gleam/dynamic
import gleam/dynamic/decode
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/io
import gleam/javascript/promise.{type Promise}
import gleam/json.{type Json}
import gleam/list
import gleam/result
import gleam/uri
import lustre/effect.{type Effect}
import rsvp

@external(javascript, "./client.ffi.mjs", "fetchWithCredentials")
fn js_fetch(
  url: String,
  method: String,
  headers: List(#(String, String)),
  body: String,
) -> Promise(dynamic.Dynamic)

pub fn send(
  req: Request(String),
  handler: fn(Result(Response(String), rsvp.Error)) -> msg,
) -> Effect(msg) {
  effect.from(fn(dispatch) {
    let method = http.method_to_string(req.method)

    let url = request.to_uri(req) |> uri.to_string

    js_fetch(url, method, req.headers, req.body)
    |> promise.map(fn(dyn) {
      let decoder = decode.one_of(decode_response(), or: [decode_error()])

      let result =
        decode.run(dyn, decoder)
        |> result.map_error(fn(_) {
          io.println_error("Failed to decode fetch response")
          rsvp.NetworkError
        })
        |> result.flatten

      handler(result)
    })
    |> promise.tap(dispatch)

    Nil
  })
}

fn decode_response() {
  use status <- decode.field("status", decode.int)
  use body <- decode.field("body", decode.string)
  use headers_list <- decode.field(
    "headers",
    decode.list(decode.list(decode.string)),
  )

  let headers =
    list.filter_map(headers_list, fn(pair) {
      case pair {
        [k, v] -> Ok(#(k, v))
        _ -> Error(Nil)
      }
    })

  decode.success(
    Ok(response.Response(status: status, headers: headers, body: body)),
  )
}

fn decode_error() {
  use _ <- decode.field("error", decode.string)
  decode.success(Error(rsvp.NetworkError))
}

pub fn get(
  url: String,
  handler: fn(Result(Response(String), rsvp.Error)) -> msg,
) -> Effect(msg) {
  case to_uri(url) {
    Ok(uri) -> {
      case request.from_uri(uri) {
        Ok(req) -> {
          let req = req |> request.set_method(http.Get)
          send(req, handler)
        }
        Error(_) -> report_bad_url(url, handler)
      }
    }
    Error(_) -> report_bad_url(url, handler)
  }
}

pub fn post(
  url: String,
  body: Json,
  handler: fn(Result(Response(String), rsvp.Error)) -> msg,
) -> Effect(msg) {
  case to_uri(url) {
    Ok(uri) -> {
      case request.from_uri(uri) {
        Ok(req) -> {
          let req =
            req
            |> request.set_method(http.Post)
            |> request.set_header("content-type", "application/json")
            |> request.set_body(json.to_string(body))
          send(req, handler)
        }
        Error(_) -> report_bad_url(url, handler)
      }
    }
    Error(_) -> report_bad_url(url, handler)
  }
}

pub fn put(
  url: String,
  body: Json,
  handler: fn(Result(Response(String), rsvp.Error)) -> msg,
) -> Effect(msg) {
  case to_uri(url) {
    Ok(uri) -> {
      case request.from_uri(uri) {
        Ok(req) -> {
          let req =
            req
            |> request.set_method(http.Put)
            |> request.set_header("content-type", "application/json")
            |> request.set_body(json.to_string(body))
          send(req, handler)
        }
        Error(_) -> report_bad_url(url, handler)
      }
    }
    Error(_) -> report_bad_url(url, handler)
  }
}

pub fn patch(
  url: String,
  body: Json,
  handler: fn(Result(Response(String), rsvp.Error)) -> msg,
) -> Effect(msg) {
  case to_uri(url) {
    Ok(uri) -> {
      case request.from_uri(uri) {
        Ok(req) -> {
          let req =
            req
            |> request.set_method(http.Patch)
            |> request.set_header("content-type", "application/json")
            |> request.set_body(json.to_string(body))
          send(req, handler)
        }
        Error(_) -> report_bad_url(url, handler)
      }
    }
    Error(_) -> report_bad_url(url, handler)
  }
}

pub fn delete(
  url: String,
  handler: fn(Result(Response(String), rsvp.Error)) -> msg,
) -> Effect(msg) {
  case to_uri(url) {
    Ok(uri) -> {
      case request.from_uri(uri) {
        Ok(req) -> {
          let req = req |> request.set_method(http.Delete)
          send(req, handler)
        }
        Error(_) -> report_bad_url(url, handler)
      }
    }
    Error(_) -> report_bad_url(url, handler)
  }
}

fn to_uri(url_str: String) -> Result(uri.Uri, Nil) {
  uri.parse(url_str)
}

fn report_bad_url(
  url: String,
  handler: fn(Result(Response(String), rsvp.Error)) -> msg,
) -> Effect(msg) {
  effect.from(fn(dispatch) { dispatch(handler(Error(rsvp.BadUrl(url)))) })
}

pub fn expect_ok_response(
  handler: fn(Result(Response(String), rsvp.Error)) -> msg,
) -> fn(Result(Response(String), rsvp.Error)) -> msg {
  fn(res: Result(Response(String), rsvp.Error)) -> msg {
    case res {
      Ok(response) -> {
        case response.status {
          code if code >= 200 && code < 300 -> handler(Ok(response))
          _ -> handler(Error(rsvp.HttpError(response)))
        }
      }
      Error(e) -> handler(Error(e))
    }
  }
}

pub fn expect_json(
  decoder: decode.Decoder(a),
  handler: fn(Result(a, rsvp.Error)) -> msg,
) -> fn(Result(Response(String), rsvp.Error)) -> msg {
  use result <- expect_ok_response

  handler({
    use response <- result.try(result)

    case json.parse(response.body, decoder) {
      Ok(val) -> Ok(val)
      Error(e) -> Error(rsvp.JsonError(e))
    }
  })
}
