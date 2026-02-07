import ffi/ffi
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import lustre/effect.{type Effect}
import namespace/namespace
import namespace/namespace_api
import note/note
import note/note_api
import plinth/javascript/storage
import pvtor_frontend/model.{type Model, Model}
import pvtor_frontend/msg.{type Msg}
import varasto

// TODO: get from env
const backend_url = "http://localhost:5000/api/"

pub fn get_selected_note() -> Effect(Msg) {
  let assert Ok(local) = storage.local()
  let s = varasto.new(local, note.note_reader(), note.note_writer())

  effect.from(fn(dispatch) {
    case varasto.get(s, "selected_note") {
      Ok(note) -> dispatch(msg.LocalStorageReturnedSelectedNote(Ok(note)))
      Error(err) -> dispatch(msg.LocalStorageReturnedSelectedNote(Error(err)))
    }
  })
}

pub fn get_selected_namespace() -> Effect(Msg) {
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

pub fn init(_args) -> #(Model, Effect(Msg)) {
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
      edit_note_content: "",
      edit_note_name: "",
    ),
    effects,
  )
}

pub fn update(model: Model, message: Msg) -> #(Model, Effect(Msg)) {
  let assert Ok(local) = storage.local()

  case message {
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

    msg.UserClickedNamespaceCard(nmspc) -> {
      let s =
        varasto.new(
          local,
          namespace.decode_namespace(),
          namespace.encode_namespace(),
        )

      #(
        Model(..model, selected_namespace: Some(nmspc)),
        case model.selected_namespace {
          None -> effect.none()
          Some(nmspc) ->
            effect.batch([
              note_api.get_namespace_notes(backend_url, nmspc.namespace_id),

              effect.from(fn(_) {
                // TODO: check for errors
                let _ = varasto.set(s, "selected_namespace", nmspc)
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
      io.println(string.inspect(err))
      #(model, effect.none())
    }

    msg.UserUpdatedNewNoteName(name) -> {
      #(Model(..model, new_note_name: name), effect.none())
    }

    msg.UserUpdatedNewNoteContent(content) -> {
      #(Model(..model, new_note_content: content), effect.none())
    }

    msg.UserUpdatedEditNoteName(name) -> {
      #(Model(..model, edit_note_name: name), effect.none())
    }

    msg.UserUpdatedEditNoteContent(content) -> {
      #(Model(..model, edit_note_content: content), effect.none())
    }

    msg.UserUpdatedNoteSearchQuery(query) -> {
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
      let #(edit_name, edit_content) = case model.selected_note {
        None -> #("", "")
        Some(note) -> #(note.name |> option.unwrap(""), note.content)
      }
      let effect = {
        use _dispatch, _root <- effect.after_paint
        ffi.show_dialog(".note-edit-dialog")
      }
      #(
        Model(
          ..model,
          edit_note_name: edit_name,
          edit_note_content: edit_content,
        ),
        effect,
      )
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
        Model(..model, edit_note_content: "", edit_note_name: ""),
        note_api.update_note(backend_url, note.note_id, Some(name), content),
      )
    }

    msg.LocalStorageReturnedSelectedNamespace(Ok(namespace)) -> #(
      Model(..model, selected_namespace: Some(namespace)),
      // NOTE: this loads on initial page load
      note_api.get_namespace_notes(backend_url, namespace.namespace_id),
    )

    msg.LocalStorageReturnedSelectedNamespace(Error(err)) -> {
      io.println(string.inspect(err))
      #(model, effect.none())
    }

    msg.ApiReturnedNotes(Ok(notes)) -> #(Model(..model, notes:), effect.none())

    msg.ApiReturnedNotes(Error(err)) -> {
      io.println(string.inspect(err))
      #(model, effect.none())
    }

    msg.ApiReturnedCreatedNote(Ok(note)) -> #(
      Model(..model, notes: [note, ..model.notes]),
      effect.none(),
    )

    msg.ApiReturnedCreatedNote(Error(err)) -> {
      io.println(string.inspect(err))
      #(model, effect.none())
    }

    msg.ApiReturnedNamespaces(Ok(namespaces)) -> #(
      Model(..model, namespaces: list.append(model.namespaces, namespaces)),
      effect.none(),
    )

    msg.ApiReturnedNamespaces(Error(err)) -> {
      io.println(string.inspect(err))
      #(model, effect.none())
    }

    // TODO: replace note, not refetch all of them
    msg.ApiReturnedUpdatedNote(_) -> {
      let effect = case model.selected_namespace {
        None -> effect.none()
        Some(namespace) ->
          note_api.get_namespace_notes(backend_url, namespace.namespace_id)
      }

      #(model, effect)
    }
  }
}
