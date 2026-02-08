import gleam/json
import lustre/effect.{type Effect}
import pvtor_frontend/msg.{
  type Msg, ApiReturnedAuthCheck, ApiReturnedLoginStatus, ApiReturnedLogoutStatus,
}
import rsvp

pub fn log_in(backend_url: String, password: String) -> Effect(Msg) {
  let body = json.object([#("password", json.string(password))])

  let url = backend_url <> "auth/login"
  let handler =
    rsvp.expect_ok_response(fn(res) {
      case res {
        Ok(_) -> ApiReturnedLoginStatus(Ok(Nil))
        Error(e) -> ApiReturnedLoginStatus(Error(e))
      }
    })

  rsvp.post(url, body, handler)
}

pub fn log_out(backend_url: String) -> Effect(Msg) {
  let body = json.object([])
  let url = backend_url <> "auth/logout"
  let handler =
    rsvp.expect_ok_response(fn(res) {
      case res {
        Ok(_) -> ApiReturnedLogoutStatus(Ok(Nil))
        Error(e) -> ApiReturnedLogoutStatus(Error(e))
      }
    })

  rsvp.post(url, body, handler)
}

pub fn check_auth(backend_url: String) -> Effect(Msg) {
  let url = backend_url <> "auth/check"
  let handler =
    rsvp.expect_ok_response(fn(res) {
      case res {
        Ok(_) -> ApiReturnedAuthCheck(Ok(Nil))
        Error(e) -> ApiReturnedAuthCheck(Error(e))
      }
    })

  rsvp.get(url, handler)
}
