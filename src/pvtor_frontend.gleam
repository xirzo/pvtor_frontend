import gleam/list
import gleam/option.{type Option, None, Some}
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import msg.{type Msg}
import note/note.{type Note}
import note/note_api
import note/note_view
import plinth/javascript/storage
import varasto

// TODO: get from env
const backend_url = "http://localhost:5000/api/"

type Model {
  Model(
    selected_note: Option(Note),
    notes: List(Note),
    is_mobile_sidebar_toggled: Bool,
  )
}

fn get_selected_note() -> Effect(Msg) {
  let assert Ok(local) = storage.local()
  let s = varasto.new(local, note.note_reader(), note.note_writer())

  effect.from(fn(dispatch) {
    case varasto.get(s, "selected_note") {
      Ok(note) -> dispatch(msg.LocalStorageReturnedSelectedNote(Ok(note)))
      Error(err) -> dispatch(msg.LocalStorageReturnedSelectedNote(Error(err)))
    }
  })
}

fn init(_args) -> #(Model, Effect(Msg)) {
  let effects =
    effect.batch([note_api.get_notes(backend_url), get_selected_note()])

  #(
    Model(selected_note: None, notes: [], is_mobile_sidebar_toggled: False),
    effects,
  )
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  let assert Ok(local) = storage.local()
  let s = varasto.new(local, note.note_reader(), note.note_writer())

  case msg {
    msg.UserClickedSidebarButton -> #(
      Model(
        ..model,
        is_mobile_sidebar_toggled: !model.is_mobile_sidebar_toggled,
      ),
      effect.none(),
    )

    msg.UserClickedNoteCard(note) -> #(
      Model(..model, selected_note: Some(note)),
      case model.selected_note {
        None -> effect.none()
        Some(note) ->
          effect.from(fn(_) {
            // TODO: check for errors
            let _ = varasto.set(s, "selected_note", note)
            Nil
          })
      },
    )

    msg.LocalStorageReturnedSelectedNote(Ok(note)) -> #(
      Model(..model, selected_note: Some(note)),
      effect.none(),
    )

    msg.LocalStorageReturnedSelectedNote(Error(err)) -> {
      echo err
      #(model, effect.none())
    }

    msg.ApiReturnedNotes(Ok(notes)) -> #(
      Model(..model, notes: list.append(model.notes, notes)),
      effect.none(),
    )

    msg.ApiReturnedNotes(Error(err)) -> {
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

fn view_content(current_note: Option(Note)) -> Element(Msg) {
  case current_note {
    Some(note) ->
      html.div([attribute.class("content-view")], [note_view.view_card(note)])

    None ->
      html.div([attribute.class("content-view")], [
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
        event.on_click(msg.UserClickedSidebarButton),
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

      html.div([attribute.class("content-area")], [
        html.div(
          [attribute.class("content-notes")],
          list.map(model.notes, note_view.view_note_card),
        ),

        view_content(model.selected_note),
      ]),
    ]),
  ])
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}
// TODO: namespace creation
// TODO: note search with queries
// TODO: namespace selection
// TODO: filter notes by namespace
