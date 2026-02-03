import gleam/option.{type Option, Some}
import gleam/dynamic/decode
import gleam/json

pub type Note {
  Note(
    note_id: Int,
    content: String,
    creation_date: String,
    namespace_id: Option(Int),
    is_hidden: Bool,
  )
}

pub fn decode_note() {
  use note_id <- decode.field("noteId", decode.int)
  use content <- decode.field("content", decode.string)
  use creation_date <- decode.field("creationDate", decode.string)
  use namespace_id <- decode.field("noteNamespaceId", decode.optional(decode.int))
  use is_hidden <- decode.field("isHidden", decode.bool)

  decode.success(Note(
    note_id:,
    content:,
    creation_date:,
    namespace_id:,
    is_hidden:,
  ))
}

// TODO: use decode_note
pub fn note_reader() {
  use content <- decode.field("content", decode.string)

  echo content

  decode.success(Note(1, content, "", Some(1), False))
}

// TODO: fill in all the values
pub  fn note_writer() {
  fn(n: Note) {
    json.object([
      #("content", json.string(n.content)),
    ])
  }
}
