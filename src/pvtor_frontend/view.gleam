import gleam/list
import gleam/option.{type Option, None, Some}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import namespace/namespace.{type Namespace}
import note/note.{type Note}
import note/note_view
import pvtor_frontend/model.{type Model}
import pvtor_frontend/msg.{type Msg}

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
      html.dialog([attribute.class("note-edit-dialog")], [
        html.div([attribute.class("new-note-dialog-content")], [
          html.p([], [html.text("Edit note")]),

          html.input([
            attribute.placeholder("Note name"),
            attribute.value(model.edit_note_name),
            event.on_input(msg.UserUpdatedEditNoteName),
          ]),

          html.input([
            attribute.placeholder("Content"),
            attribute.value(model.edit_note_content),
            event.on_input(msg.UserUpdatedEditNoteContent),
          ]),

          html.button(
            [
              event.on_click(msg.UserClickedEditNoteButton(
                note,
                model.edit_note_name,
                model.edit_note_content,
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

pub fn view(model: Model) -> Element(Msg) {
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
        html.div([attribute.class("content-notes")], [
          html.select([event.on_change(msg.UserChangedNoteSortOrder)], [
            html.option([attribute.value("update_date")], "By update date"),
          ]),
          ..list.map(model.notes, note_view.view_note_card)
        ]),

        view_content(model.selected_note),
      ]),
    ]),
  ])
}
