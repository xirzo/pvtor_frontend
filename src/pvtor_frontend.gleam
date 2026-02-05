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
import namespace/namespace.{type Namespace}
import namespace/namespace_api
import note/note_api
import note/note_view
import plinth/javascript/storage
import varasto

// TODO: get from env
const backend_url = "http://localhost:5000/api/"

type Model {
  Model(
    selected_note: Option(Note),
    selected_namespace: Option(Namespace),
    notes: List(Note),
    namespaces: List(Namespace),
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

fn get_selected_namespace() -> Effect(Msg) {
  let assert Ok(local) = storage.local()
  let s = varasto.new(local, namespace.decode_namespace(), namespace.encode_namespace())

  effect.from(fn(dispatch) {
    case varasto.get(s, "selected_namespace") {
      Ok(note) -> dispatch(msg.LocalStorageReturnedSelectedNamespace(Ok(note)))
      Error(err) -> dispatch(msg.LocalStorageReturnedSelectedNamespace(Error(err)))
    }
  })
}

fn init(_args) -> #(Model, Effect(Msg)) {
  let effects =
    effect.batch([note_api.get_notes(backend_url), get_selected_note(), namespace_api.get_namespaces(backend_url), get_selected_namespace()])

  #(
    Model(selected_note: None, selected_namespace: None, notes: [], namespaces: [], is_mobile_sidebar_toggled: False),
    effects,
  )
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  let assert Ok(local) = storage.local()

  case msg {
    msg.UserClickedSidebarButton -> #(
      Model(
        ..model,
        is_mobile_sidebar_toggled: !model.is_mobile_sidebar_toggled,
      ),
      effect.none(),
    )

    msg.UserClickedNoteCard(note) -> {
      let s = varasto.new(local, note.note_reader(), note.note_writer())
      #(Model(..model, selected_note: Some(note)),
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
    }

    msg.UserClickedNamespaceCard(namespace) -> {
      let s = varasto.new(local, namespace.decode_namespace(), namespace.encode_namespace())

      #(Model(..model, selected_namespace: Some(namespace)),
	case model.selected_namespace {
	  None -> effect.none()
	  Some(namespace) ->
	    effect.from(fn(_) {
	    // TODO: check for errors
	      let _ = varasto.set(s, "selected_namespace", namespace)
	      Nil
	    })
	},
      )
    }

    msg.LocalStorageReturnedSelectedNote(Ok(note)) -> #(
      Model(..model, selected_note: Some(note)),
      effect.none(),
    )

    msg.LocalStorageReturnedSelectedNote(Error(err)) -> {
      echo err
      #(model, effect.none())
    }

    msg.LocalStorageReturnedSelectedNamespace(Ok(namespace)) -> #(
      Model(..model, selected_namespace: Some(namespace)),
      effect.none(),
    )

    msg.LocalStorageReturnedSelectedNamespace(Error(err)) -> {
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

    msg.ApiReturnedNamespaces(Ok(namespaces)) -> #(
      Model(..model, namespaces: list.append(model.namespaces, namespaces)),
      effect.none(),
    )

    msg.ApiReturnedNamespaces(Error(err)) -> {
      echo err
      #(model, effect.none())
    }
  }
}

// use lowercase msg: https://github.com/lustre-labs/lustre/blob/main/examples/01-basics/03-view-functions/src/app.gleam
fn view_namespace_card(namespace: Namespace) -> Element(Msg) {
  html.div([attribute.class("namespace-card")], [
    html.button([event.on_click(msg.UserClickedNamespaceCard(namespace)), attribute.class("namespace-card-button")], [html.text(namespace.name)]),
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

      html.div([], list.map(model.namespaces, view_namespace_card(_)))
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
