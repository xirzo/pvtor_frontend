import gleam/dynamic/decode
import gleam/json

pub type Namespace {
  Namespace(namespace_id: Int, name: String, creation_date: String)
}

pub fn decode_namespace() {
  use namespace_id <- decode.field("noteNamespaceId", decode.int)
  use name <- decode.field("name", decode.string)
  use creation_date <- decode.field("creationDate", decode.string)

  decode.success(Namespace(
    namespace_id:,
    name:,
    creation_date:,
  ))
}

pub fn encode_namespace() {
  fn(n: Namespace) {
    json.object([
      #("noteNamespaceId", json.int(n.namespace_id)),
      #("name", json.string(n.name)),
      #("creationDate", json.string(n.creation_date)),
    ])
  }
}
