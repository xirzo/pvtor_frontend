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
import pvtor_frontend/model
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

pub fn init(_args) -> #(model.Model, Effect(Msg)) {
  let effects =
    effect.batch([
      get_selected_note(),
      get_selected_namespace(),
      namespace_api.get_namespaces(backend_url),
    ])

  #(
    model.LoggedIn(model.LoggedInModel(
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
    )),
    effects,
  )
}

fn update_logged_in_model(
  logged_in_model: model.LoggedInModel,
  message: Msg,
) -> #(model.Model, Effect(Msg)) {
  let assert Ok(local) = storage.local()

  case message {
    msg.UserClickedSidebarButton -> {
      let mod =
        model.LoggedInModel(
          ..logged_in_model,
          is_mobile_sidebar_toggled: !logged_in_model.is_mobile_sidebar_toggled,
        )

      #(model.LoggedIn(mod), effect.none())
    }

    msg.UserClickedNewNoteButton -> {
      let effect = {
        use _dispatch, _root <- effect.after_paint
        ffi.show_dialog(".new-note-dialog")
      }
      #(model.LoggedIn(logged_in_model), effect)
    }

    msg.UserClickedNoteCard(note) -> {
      let s = varasto.new(local, note.note_reader(), note.note_writer())
      #(
        model.LoggedIn(
          model.LoggedInModel(..logged_in_model, selected_note: Some(note)),
        ),
        case logged_in_model.selected_note {
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

    msg.UserClickedNamespaceCard(nmspc) -> {
      let s =
        varasto.new(
          local,
          namespace.decode_namespace(),
          namespace.encode_namespace(),
        )

      #(
        model.LoggedIn(
          model.LoggedInModel(
            ..logged_in_model,
            selected_namespace: Some(nmspc),
          ),
        ),
        case logged_in_model.selected_namespace {
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
      model.LoggedIn(
        model.LoggedInModel(..logged_in_model, selected_note: Some(note)),
      ),
      effect.none(),
    )

    msg.LocalStorageReturnedSelectedNote(Error(err)) -> {
      io.println(string.inspect(err))
      #(model.LoggedIn(logged_in_model), effect.none())
    }

    msg.UserUpdatedNewNoteName(name) -> {
      #(
        model.LoggedIn(
          model.LoggedInModel(..logged_in_model, new_note_name: name),
        ),
        effect.none(),
      )
    }

    msg.UserUpdatedNewNoteContent(content) -> {
      #(
        model.LoggedIn(
          model.LoggedInModel(..logged_in_model, new_note_content: content),
        ),
        effect.none(),
      )
    }

    msg.UserUpdatedEditNoteName(name) -> {
      #(
        model.LoggedIn(
          model.LoggedInModel(..logged_in_model, edit_note_name: name),
        ),
        effect.none(),
      )
    }

    msg.UserUpdatedEditNoteContent(content) -> {
      #(
        model.LoggedIn(
          model.LoggedInModel(..logged_in_model, edit_note_content: content),
        ),
        effect.none(),
      )
    }

    msg.UserUpdatedNoteSearchQuery(query) -> {
      case logged_in_model.selected_namespace {
        None -> {
          #(
            model.LoggedIn(
              model.LoggedInModel(..logged_in_model, note_search_query: query),
            ),
            effect.none(),
          )
        }
        Some(namespace) -> {
          case query {
            "" -> #(
              model.LoggedIn(
                model.LoggedInModel(..logged_in_model, note_search_query: query),
              ),
              note_api.get_namespace_notes(backend_url, namespace.namespace_id),
            )
            _ -> #(
              model.LoggedIn(
                model.LoggedInModel(..logged_in_model, note_search_query: query),
              ),
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
      let #(edit_name, edit_content) = case logged_in_model.selected_note {
        None -> #("", "")
        Some(note) -> #(note.name |> option.unwrap(""), note.content)
      }
      let effect = {
        use _dispatch, _root <- effect.after_paint
        ffi.show_dialog(".note-edit-dialog")
      }
      #(
        model.LoggedIn(
          model.LoggedInModel(
            ..logged_in_model,
            edit_note_name: edit_name,
            edit_note_content: edit_content,
          ),
        ),
        effect,
      )
    }

    msg.UserClickedCreateNoteButton(name, content, namespace_id) -> {
      case namespace_id {
        None -> #(model.LoggedIn(logged_in_model), effect.none())
        Some(n_id) -> #(
          model.LoggedIn(
            model.LoggedInModel(
              ..logged_in_model,
              new_note_content: "",
              new_note_name: "",
            ),
          ),
          note_api.create_note(backend_url, Some(name), content, Some(n_id)),
        )
      }
    }

    msg.UserClickedEditNoteButton(note, name, content) -> {
      #(
        model.LoggedIn(
          model.LoggedInModel(
            ..logged_in_model,
            edit_note_content: "",
            edit_note_name: "",
          ),
        ),
        note_api.update_note(backend_url, note.note_id, Some(name), content),
      )
    }

    msg.LocalStorageReturnedSelectedNamespace(Ok(namespace)) -> #(
      model.LoggedIn(
        model.LoggedInModel(
          ..logged_in_model,
          selected_namespace: Some(namespace),
        ),
      ),
      // NOTE: this loads on initial page load
      note_api.get_namespace_notes(backend_url, namespace.namespace_id),
    )

    msg.LocalStorageReturnedSelectedNamespace(Error(err)) -> {
      io.println(string.inspect(err))
      #(model.LoggedIn(logged_in_model), effect.none())
    }

    msg.ApiReturnedNotes(Ok(notes)) -> #(
      model.LoggedIn(model.LoggedInModel(..logged_in_model, notes:)),
      effect.none(),
    )

    msg.ApiReturnedNotes(Error(err)) -> {
      io.println(string.inspect(err))
      #(model.LoggedIn(logged_in_model), effect.none())
    }

    msg.ApiReturnedCreatedNote(Ok(note)) -> #(
      model.LoggedIn(
        model.LoggedInModel(..logged_in_model, notes: [
          note,
          ..logged_in_model.notes
        ]),
      ),
      effect.none(),
    )

    msg.ApiReturnedCreatedNote(Error(err)) -> {
      io.println(string.inspect(err))
      #(model.LoggedIn(logged_in_model), effect.none())
    }

    msg.ApiReturnedNamespaces(Ok(namespaces)) -> #(
      model.LoggedIn(
        model.LoggedInModel(
          ..logged_in_model,
          namespaces: list.append(logged_in_model.namespaces, namespaces),
        ),
      ),
      effect.none(),
    )

    msg.ApiReturnedNamespaces(Error(err)) -> {
      io.println(string.inspect(err))
      #(model.LoggedIn(logged_in_model), effect.none())
    }

    // TODO: replace note, not refetch all of them
    msg.ApiReturnedUpdatedNote(_) -> {
      let effect = case logged_in_model.selected_namespace {
        None -> effect.none()
        Some(namespace) ->
          note_api.get_namespace_notes(backend_url, namespace.namespace_id)
      }

      #(model.LoggedIn(logged_in_model), effect)
    }

    // TODO: implement order switching
    msg.UserChangedNoteSortOrder(_) -> #(
      model.LoggedIn(logged_in_model),
      effect.none(),
    )

    msg.UserClickedDeleteButton -> {
      let s = varasto.new(local, note.note_reader(), note.note_writer())

      let effect =
        effect.batch([
          case logged_in_model.selected_note {
            None -> effect.none()
            Some(note) -> note_api.delete_note(backend_url, note.note_id)
          },
          effect.from(fn(_) {
            // TODO: check for errors
            let _ = varasto.remove(s, "selected_note")
            Nil
          }),
        ])

      #(
        model.LoggedIn(
          model.LoggedInModel(..logged_in_model, selected_note: None),
        ),
        effect,
      )
    }
  }
}

fn update_public_model(
  model: model.PublicModel,
  _message: Msg,
) -> #(model.Model, Effect(Msg)) {
  #(model.Public(model), effect.none())
}

pub fn update(model: model.Model, message: Msg) -> #(model.Model, Effect(Msg)) {
  case model {
    model.LoggedIn(logged_in_model) ->
      update_logged_in_model(logged_in_model, message)

    model.Public(public_model) -> update_public_model(public_model, message)
  }
}
