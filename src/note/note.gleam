import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option, Some}

pub type Note {
  Note(
    note_id: Int,
    content: String,
    creation_date: String,
    namespace_id: Option(Int),
    is_hidden: Bool,
    name: Option(String),
  )
}

pub fn decode_note() {
  use note_id <- decode.field("noteId", decode.int)
  use content <- decode.field("content", decode.string)
  use creation_date <- decode.field("creationDate", decode.string)
  use namespace_id <- decode.field(
    "noteNamespaceId",
    decode.optional(decode.int),
  )
  use is_hidden <- decode.field("isHidden", decode.bool)
  use name <- decode.field("name", decode.optional(decode.string))

  decode.success(Note(
    note_id:,
    content:,
    creation_date:,
    namespace_id:,
    is_hidden:,
    name:,
  ))
}

pub fn note_reader() {
  decode_note()
}

// TODO: fill in all the values
pub fn note_writer() {
  fn(n: Note) {
    json.object([
      #("noteId", json.int(n.note_id)),
      #("content", json.string(n.content)),
      #("creationDate", json.string(n.creation_date)),
      #("noteNamespaceId", json.nullable(n.namespace_id, of: json.int)),
      #("isHidden", json.bool(n.is_hidden)),
      #("name", json.nullable(n.name, of: json.string)),
    ])
  }
}
