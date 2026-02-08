import api/client
import gleam/dynamic/decode
import lustre/effect.{type Effect}
import namespace/namespace
import pvtor_frontend/msg.{type Msg, ApiReturnedNamespaces}

pub fn get_namespaces(backend_url: String) -> Effect(Msg) {
  let decoder = namespace.decode_namespace()
  let url = backend_url <> "namespaces"
  let handler = client.expect_json(decode.list(decoder), ApiReturnedNamespaces)

  client.get(url, handler)
}
