import gleam/dynamic/decode
import lustre/effect.{type Effect}
import msg.{type Msg, ApiReturnedNotes}
import note/note
import rsvp

pub fn get_notes(backend_url: String) -> Effect(Msg) {
  let decoder = note.decode_note()
  let url = backend_url <> "notes"
  let handler = rsvp.expect_json(decode.list(decoder), ApiReturnedNotes)

  rsvp.get(url, handler)
}
