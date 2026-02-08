import api/client
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/option.{type Option}
import lustre/effect.{type Effect}
import note/note
import pvtor_frontend/msg.{type Msg, ApiReturnedNotes}

pub fn get_notes(backend_url: String) -> Effect(Msg) {
  let decoder = note.decode_note()
  let url = backend_url <> "notes"

  let handler = client.expect_json(decode.list(decoder), ApiReturnedNotes)

  client.get(url, handler)
}

pub fn get_content_namespace_notes(
  backend_url: String,
  content: String,
  namespace_id: Int,
) -> Effect(Msg) {
  let decoder = note.decode_note()
  let url =
    backend_url
    <> "notes?content="
    <> content
    <> "&namespaceIds="
    <> int.to_string(namespace_id)
  let handler = client.expect_json(decode.list(decoder), ApiReturnedNotes)

  client.get(url, handler)
}

pub fn get_namespace_notes(
  backend_url: String,
  namespace_id: Int,
) -> Effect(Msg) {
  let decoder = note.decode_note()
  let url = backend_url <> "notes?namespaceIds=" <> int.to_string(namespace_id)

  let handler = client.expect_json(decode.list(decoder), ApiReturnedNotes)

  client.get(url, handler)
}

pub fn create_note(
  backend_url: String,
  name: Option(String),
  content: String,
  namespace_id: Option(Int),
) -> Effect(Msg) {
  let body =
    json.object([
      #("name", json.nullable(name, of: json.string)),
      #("content", json.string(content)),
      #("namespaceId", json.nullable(namespace_id, of: json.int)),
    ])

  let decoder = note.decode_note()
  let url = backend_url <> "notes"
  let handler = client.expect_json(decoder, msg.ApiReturnedCreatedNote)

  client.post(url, body, handler)
}

pub fn update_note(
  backend_url: String,
  note_id: Int,
  name: Option(String),
  content: String,
) -> Effect(Msg) {
  let body =
    json.object([
      #("name", json.nullable(name, of: json.string)),
      #("content", json.string(content)),
    ])

  let decoder = note.decode_note()
  let url = backend_url <> "notes/" <> int.to_string(note_id)
  let handler = client.expect_json(decoder, msg.ApiReturnedUpdatedNote)

  client.patch(url, body, handler)
}

pub fn delete_note(backend_url: String, note_id: Int) -> Effect(Msg) {
  let decoder = note.decode_note()
  let url = backend_url <> "notes/" <> int.to_string(note_id)
  let handler = client.expect_json(decoder, msg.ApiReturnedUpdatedNote)

  client.delete(url, handler)
}
