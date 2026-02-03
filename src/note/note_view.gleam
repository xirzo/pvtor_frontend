import lustre/attribute
import lustre/element/html
import lustre/element.{type Element}
import lustre/event
import note/note.{type Note}
import msg.{type Msg}
import tempo
import tempo/datetime

pub fn view_note_card(note: Note) -> Element(Msg) {
  html.button([
    attribute.class("note-card"),
    event.on_click(msg.UserClickedNoteCard(note)),
  ], [
    html.p([], [html.text(note.content)]),
  ])
}

pub fn view_card(note: Note) -> Element(Msg) {
  let time = datetime.literal(note.creation_date)
  |> datetime.format(tempo.Custom("dddd D, MMMM h:m, YYYY"))

  html.div([attribute.class("note-content")], [

    html.b([], [html.text("Creation date")]),
    html.p([], [html.text(time)]),

    html.b([], [html.text("Note content")]),

    html.button([attribute.class("note-content-edit-button")], [html.text("Edit")]),

    html.p([], [html.text(note.content)]),

    html.b([], [html.text("Metadata")]),
  ])
}
