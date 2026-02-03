import gleam/bool
import gleam/option.{None, type Option, Some}
import gleam/dynamic/decode
import gleam/list
import gleam/json
import plinth/javascript/storage
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import rsvp
import varasto

// TODO: get from env
const backend_url = "http://localhost:5000/api/"

fn decode_note() {
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


fn get_notes() -> Effect(Msg) {
  let decoder = decode_note()
  let url = backend_url <> "notes"
  let handler = rsvp.expect_json(decode.list(decoder), ApiReturnedNotes)

  rsvp.get(url, handler)
}

type Note {
  Note(
    note_id: Int,
    content: String,
    creation_date: String,
    namespace_id: Option(Int),
    is_hidden: Bool,
  )
}

type Model {
  Model(selected_note: Option(Note), notes: List(Note), is_mobile_sidebar_toggled: Bool)
}

fn get_selected_note() -> Effect(Msg) {
  let assert Ok(local) = storage.local()
  let s = varasto.new(local, note_reader(),  note_writer())

  effect.from(fn(dispatch) {
    case varasto.get(s, "selected_note") {
      Ok(note) -> dispatch(LocalStorageReturnedSelectedNote(Ok(note)))
      Error(err) -> dispatch(LocalStorageReturnedSelectedNote(Error(err)))
    }
  })
}

fn init(_args) -> #(Model, Effect(Msg)) {
  let effects = effect.batch([
    get_notes(),
    get_selected_note()
  ])

  #(Model(selected_note: None, notes: [], is_mobile_sidebar_toggled: False), effects)
}

type Msg {
  UserClickedSidebarButton
  UserClickedNoteCard(Note)
  ApiReturnedNotes(Result(List(Note), rsvp.Error))
  LocalStorageReturnedSelectedNote(Result(Note, varasto.ReadError))
}

// TODO: use decode_note
fn note_reader() {
  use content <- decode.field("content", decode.string)

  echo content

  decode.success(Note(1, content, "", Some(1), False,))
}

// TODO: fill in all the values
fn note_writer() {
  fn(n: Note) {
    json.object([
      #("content", json.string(n.content)),
    ])
  }
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  let assert Ok(local) = storage.local()
  let s = varasto.new(local, note_reader(),  note_writer())

  case msg {
    UserClickedSidebarButton -> #(
      Model(
        ..model,
        is_mobile_sidebar_toggled: !model.is_mobile_sidebar_toggled,
      ),
      effect.none(),
    )

    UserClickedNoteCard(note) -> #(
      Model(..model, selected_note: Some(note)),
      case model.selected_note {
	None -> effect.none()
	Some(note) -> effect.from(fn(_) {
	// TODO: check for errors
	  let _ = varasto.set(s, "selected_note", note)
	  Nil
	})
      }
    )

    LocalStorageReturnedSelectedNote(Ok(note)) -> #(
      Model(..model, selected_note: Some(note)),
      effect.none()
    )
      
    LocalStorageReturnedSelectedNote(Error(err)) -> {
      echo err
      #(model, effect.none())
    }

    ApiReturnedNotes(Ok(notes)) -> #(
      Model(..model, notes: list.append(model.notes, notes)),
      effect.none(),
    )

    ApiReturnedNotes(Error(err)) -> {
      echo err
      #(model, effect.none())
    }
  }
}

fn view_namespace_card(namespace_name: String) -> Element(Msg) {
  html.div([attribute.class("namespace-card")], [
    html.p([], [html.text(namespace_name)]),
  ])
}

fn view_note_card(note: Note) -> Element(Msg) {
  html.button([
    attribute.class("note-card"),
    event.on_click(UserClickedNoteCard(note)),
  ], [
    html.p([], [html.text(note.content)]),
  ])
}

fn view_content(current_note: Option(Note)) -> Element(Msg) {
  case current_note {
    Some(note) -> html.div([attribute.class("content-view")], [
      html.text(note.content)
    ])

    None ->  html.div([attribute.class("content-view")], [
	html.p([], [html.text("No note selected")]),
    ])
  }
}

fn view(model: Model) -> Element(Msg) {
  let namespaces = ["Work", "Personal", "Ideas"]

  let sidebar_class = case model.is_mobile_sidebar_toggled {
    True -> "sidebar-open"
    False -> "sidebar"
  }

  html.div([attribute.class("main")], [
    html.button(
      [
        attribute.class("mobile-menu-button"),
        event.on_click(UserClickedSidebarButton),
      ],
      [html.text("☰")],
    ),

    html.div([attribute.class(sidebar_class)], [
      html.div([attribute.class("sidebar-header")], [
        html.text("Pvtor Dashboard"),
      ]),

      html.div([attribute.class("namespaces-section")], [
        html.text("Namespaces"),
        html.button([attribute.class("new-namespace-button")], [
          html.text("New namespace"),
        ]),
      ]),

      html.div([], list.map(namespaces, view_namespace_card)),
    ]),

    html.div([attribute.class("main-content")], [
      html.div([attribute.class("top-bar")], [
        html.div([attribute.class("search-section")], [
          html.input([
            attribute.placeholder("Search notes..."),
            attribute.class("search-input"),
          ]),

          html.button([attribute.class("new-note-button")], [
            html.text("New note"),
          ]),
        ]),
      ]),

      html.div(
        [attribute.class("content-area")],
	[
	  html.div([attribute.class("content-notes")], list.map(model.notes, view_note_card)),

	  view_content(model.selected_note)
	],
      ),
    ]),
  ])
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

// TODO: add note names to note representation
// TODO: namespace creation
// TODO: note creation
// TODO: note search with queries
// TODO: note selection
// TODO: namespace selection
// TODO: filter notes by namespace
