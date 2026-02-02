import gleam/bool
import gleam/option.{None, type Option, Some}
import gleam/dynamic/decode
import gleam/list
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import rsvp

// TODO: get from env
const backend_url = "http://localhost:5000/api/"

fn get_notes() -> Effect(Msg) {
  let decoder = {
    use note_id <- decode.field("note_id", decode.int)
    use content <- decode.field("content", decode.string)
    use creation_date <- decode.field("creation_date", decode.string)
    use update_date <- decode.field("update_date", decode.string)
    use namespace_id <- decode.field("namespace_id", decode.int)
    use is_hidden <- decode.field("is_hidden", decode.bool)

    decode.success(Note(
      note_id:,
      content:,
      creation_date:,
      update_date:,
      namespace_id:,
      is_hidden:,
    ))
  }

  let url = backend_url <> "notes"
  let handler = rsvp.expect_json(decode.list(decoder), ApiReturnedNotes)

  rsvp.get(url, handler)
}

type Note {
  Note(
    note_id: Int,
    content: String,
    creation_date: String,
    update_date: String,
    namespace_id: Int,
    is_hidden: Bool,
  )
}

type Model {
  Model(selected_note: Option(Note), notes: List(Note), is_mobile_sidebar_toggled: Bool)
}

fn init(_args) -> #(Model, Effect(Msg)) {
  let effect = get_notes()
  #(Model(selected_note: None, notes: [], is_mobile_sidebar_toggled: False), effect)
}

type Msg {
  UserClickedSidebarButton
  ApiReturnedNotes(Result(List(Note), rsvp.Error))
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserClickedSidebarButton -> #(
      Model(
        ..model,
        is_mobile_sidebar_toggled: !model.is_mobile_sidebar_toggled,
      ),
      effect.none(),
    )

    ApiReturnedNotes(Ok(notes)) -> #(
      Model(..model, notes: list.append(model.notes, notes)),
      effect.none(),
    )

    ApiReturnedNotes(Error(_)) -> #(model, effect.none())
  }
}

fn view_namespace_card(namespace_name: String) -> Element(Msg) {
  html.div([attribute.class("namespace-card")], [
    html.p([], [html.text(namespace_name)]),
  ])
}

fn view_note_card(note: Note) -> Element(Msg) {
  html.div([attribute.class("note-card")], [
    html.p([], [html.text(note.content)]),
  ])
}

fn view_content(current_note: Option(Note)) -> Element(Msg) {
  case current_note {
    Some(_) -> html.div([attribute.class("content-view")], [
      html.text("Selected note placeholder")
    ])

    None ->  html.div([attribute.class("content-view-empty")], [
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
