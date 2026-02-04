import gleam/bool
import gleam/int
import gleam/option.{None, Some}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import msg.{type Msg}
import note/note.{type Note}
import tempo
import tempo/datetime

pub fn view_note_card(note: Note) -> Element(Msg) {
  html.button(
    [
      attribute.class("note-card"),
      event.on_click(msg.UserClickedNoteCard(note)),
    ],
    [
      html.p([], [html.text(note.content)]),
    ],
  )
}

pub fn view_card(note: Note) -> Element(Msg) {
  let time =
    datetime.literal(note.creation_date)
    |> datetime.format(tempo.Custom("dddd D, MMMM h:m, YYYY"))

  let namespace_id = case note.namespace_id {
    None -> "Default namespace"
    Some(namespace) -> int.to_string(namespace)
  }

  html.div([attribute.class("note-content")], [
    html.b([], [html.text("Creation date")]),
    html.p([], [html.text(time)]),

    html.b([], [html.text("Note content")]),

    html.button([attribute.class("note-content-edit-button")], [
      html.text("Edit"),
    ]),

    html.p([], [html.text(note.content)]),

    html.b([], [html.text("Metadata")]),

    html.p([], [html.text("Namespace ID: " <> namespace_id)]),
    html.p([], [html.text("IsHidden ID: " <> bool.to_string(note.is_hidden))]),
  ])
}
