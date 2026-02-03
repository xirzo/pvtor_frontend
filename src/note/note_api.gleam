import lustre/effect.{type Effect}
import note/note
import rsvp
import msg.{type Msg, ApiReturnedNotes}
import gleam/dynamic/decode

pub fn get_notes(backend_url: String) -> Effect(Msg) {
  let decoder = note.decode_note()
  let url = backend_url <> "notes"
  let handler = rsvp.expect_json(decode.list(decoder), ApiReturnedNotes)

  rsvp.get(url, handler)
}
