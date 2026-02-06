import ffi
import gleam/list
import gleam/option.{type Option, None, Some}
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import msg.{type Msg}
import namespace/namespace.{type Namespace}
import namespace/namespace_api
import note/note.{type Note}
import note/note_api
import note/note_view
import plinth/javascript/storage
import varasto

// TODO: get from env
const backend_url = "http://localhost:5000/api/"

type Model {
  Model(
    note_search_query: String,
    selected_note: Option(Note),
    selected_namespace: Option(Namespace),
    notes: List(Note),
    namespaces: List(Namespace),
    is_mobile_sidebar_toggled: Bool,
    new_note_content: String,
    new_note_name: String,
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
  let s =
    varasto.new(
      local,
      namespace.decode_namespace(),
      namespace.encode_namespace(),
    )

  effect.from(fn(dispatch) {
    case varasto.get(s, "selected_namespace") {
      Ok(note) -> dispatch(msg.LocalStorageReturnedSelectedNamespace(Ok(note)))
      Error(err) ->
        dispatch(msg.LocalStorageReturnedSelectedNamespace(Error(err)))
    }
  })
}

fn init(_args) -> #(Model, Effect(Msg)) {
  let effects =
    effect.batch([
      get_selected_note(),
      get_selected_namespace(),
      namespace_api.get_namespaces(backend_url),
    ])

  #(
    Model(
      note_search_query: "",
      selected_note: None,
      selected_namespace: None,
      notes: [],
      namespaces: [],
      is_mobile_sidebar_toggled: False,
      new_note_content: "",
      new_note_name: "",
    ),
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

    msg.UserClickedNewNoteButton -> {
      let effect = {
        use _dispatch, _root <- effect.after_paint
        ffi.show_dialog(".new-note-dialog")
      }
      #(model, effect)
    }

    msg.UserClickedNoteCard(note) -> {
      let s = varasto.new(local, note.note_reader(), note.note_writer())
      #(Model(..model, selected_note: Some(note)), case model.selected_note {
        None -> effect.none()
        Some(note) ->
          effect.from(fn(_) {
            // TODO: check for errors
            let _ = varasto.set(s, "selected_note", note)
            Nil
          })
      })
    }

    msg.UserClickedNamespaceCard(namespace) -> {
      let s =
        varasto.new(
          local,
          namespace.decode_namespace(),
          namespace.encode_namespace(),
        )

      #(
        Model(..model, selected_namespace: Some(namespace)),
        case model.selected_namespace {
          None -> effect.none()
          Some(namespace) ->
            effect.batch([
              note_api.get_namespace_notes(backend_url, namespace.namespace_id),

              effect.from(fn(_) {
                // TODO: check for errors
                let _ = varasto.set(s, "selected_namespace", namespace)
                Nil
              }),
            ])
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

    msg.UserUpdatedNewNoteName(name) -> {
      #(Model(..model, new_note_name: name), effect.none())
    }

    msg.UserUpdatedNewNoteContent(content) -> {
      #(Model(..model, new_note_content: content), effect.none())
    }

    msg.UserUpdatedNoteSearchQuery(query) -> {
      // TODO: возможно здесь ошибки (почитать про полнотекстовый поиск)
      case model.selected_namespace {
        None -> {
          #(Model(..model, note_search_query: query), effect.none())
        }
        Some(namespace) -> {
          case query {
            "" -> #(
              Model(..model, note_search_query: query),
              note_api.get_namespace_notes(backend_url, namespace.namespace_id),
            )
            _ -> #(
              Model(..model, note_search_query: query),
              note_api.get_content_namespace_notes(
                backend_url,
                query,
                namespace.namespace_id,
              ),
            )
          }
        }
      }
    }

    msg.UserClickedEditButton -> {
      let effect = {
        use _dispatch, _root <- effect.after_paint
        ffi.show_dialog(".note-edit-dialog")
      }
      #(model, effect)
    }

    msg.UserClickedCreateNoteButton(name, content, namespace_id) -> {
      case namespace_id {
        None -> #(model, effect.none())
        Some(n_id) -> #(
          Model(..model, new_note_content: "", new_note_name: ""),
          note_api.create_note(backend_url, Some(name), content, Some(n_id)),
        )
      }
    }

    msg.UserClickedEditNoteButton(note, name, content) -> {
      #(
        Model(..model, new_note_content: "", new_note_name: ""),
        note_api.update_note(
          backend_url,
          note.note_id,
          Some(name),
          content,
          note.namespace_id,
        ),
      )
    }

    msg.LocalStorageReturnedSelectedNamespace(Ok(namespace)) -> #(
      Model(..model, selected_namespace: Some(namespace)),
      // NOTE: this loads on initial page load
      note_api.get_namespace_notes(backend_url, namespace.namespace_id),
    )

    msg.LocalStorageReturnedSelectedNamespace(Error(err)) -> {
      echo err
      #(model, effect.none())
    }

    msg.ApiReturnedNotes(Ok(notes)) -> #(Model(..model, notes:), effect.none())

    msg.ApiReturnedNotes(Error(err)) -> {
      echo err
      #(model, effect.none())
    }

    msg.ApiReturnedCreatedNote(Ok(note)) -> #(
      Model(..model, notes: [note, ..model.notes]),
      effect.none(),
    )

    msg.ApiReturnedCreatedNote(Error(err)) -> {
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
    msg.ApiReturnedUpdatedNote(_) -> todo
  }
}

fn view_namespace_card(nmspc: Namespace) -> Element(Msg) {
  let n = case nmspc.name {
    "" -> namespace.Namespace(..nmspc, name: "default")
    _ -> nmspc
  }

  html.div([attribute.class("namespace-card")], [
    html.button(
      [
        event.on_click(msg.UserClickedNamespaceCard(nmspc)),
        attribute.class("namespace-card-button"),
      ],
      [html.text(n.name)],
    ),
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

fn view_edit_note_dialog(model: Model) -> Element(Msg) {
  case model.selected_note {
    None -> {
      html.dialog([attribute.class("note-edit-dialog")], [
        html.div([attribute.class("new-note-dialog-content")], [
          html.p([], [html.text("No note selected!")]),
        ]),
      ])
    }
    Some(note) -> {
      let name = case note.name {
        None -> ""
        Some(n) -> n
      }

      html.dialog([attribute.class("note-edit-dialog")], [
        html.div([attribute.class("new-note-dialog-content")], [
          html.p([], [html.text("New note dialog")]),

          html.input([
            attribute.placeholder("Note name"),
            attribute.value(model.new_note_name),
            event.on_input(msg.UserUpdatedNewNoteName),
          ]),

          html.input([
            attribute.placeholder("Content"),
            attribute.value(model.new_note_content),
            event.on_input(msg.UserUpdatedNewNoteContent),
          ]),

          html.button(
            [
              event.on_click(msg.UserClickedEditNoteButton(
                note,
                model.new_note_name,
                model.new_note_content,
              )),
            ],
            [html.text("Edit note")],
          ),
        ]),
      ])
    }
  }
}

fn view_new_note_dialog(model: Model) -> Element(Msg) {
  let namespace_id = case model.selected_namespace {
    None -> None
    Some(n) -> Some(n.namespace_id)
  }

  html.dialog([attribute.class("new-note-dialog")], [
    html.div([attribute.class("new-note-dialog-content")], [
      html.p([], [html.text("New note dialog")]),

      html.input([
        attribute.placeholder("Note name"),
        attribute.value(model.new_note_name),
        event.on_input(msg.UserUpdatedNewNoteName),
      ]),

      html.input([
        attribute.placeholder("Content"),
        attribute.value(model.new_note_content),
        event.on_input(msg.UserUpdatedNewNoteContent),
      ]),

      html.button(
        [
          event.on_click(msg.UserClickedCreateNoteButton(
            model.new_note_name,
            model.new_note_content,
            namespace_id,
          )),
        ],
        [html.text("Create note")],
      ),
    ]),
  ])
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

    view_new_note_dialog(model),
    view_edit_note_dialog(model),

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

      html.div([], list.map(model.namespaces, view_namespace_card)),
    ]),

    html.div([attribute.class("main-content")], [
      html.div([attribute.class("top-bar")], [
        html.div([attribute.class("search-section")], [
          html.input([
            attribute.class("search-input"),
            attribute.placeholder("Search notes..."),
            attribute.value(model.note_search_query),
            event.on_input(msg.UserUpdatedNoteSearchQuery),
          ]),

          html.button(
            [
              attribute.class("new-note-button"),
              event.on_click(msg.UserClickedNewNoteButton),
            ],
            [
              html.text("New note"),
            ],
          ),
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
// TODO: note search with queries (for start fulltext search)
