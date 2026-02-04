import gleam/dynamic/decode
import lustre/effect.{type Effect}
import msg.{type Msg, ApiReturnedNamespaces}
import namespace/namespace
import rsvp

pub fn get_namespaces(backend_url: String) -> Effect(Msg) {
  let decoder = namespace.decode_namespace()
  let url = backend_url <> "namespaces"
  let handler = rsvp.expect_json(decode.list(decoder), ApiReturnedNamespaces)

  rsvp.get(url, handler)
}
