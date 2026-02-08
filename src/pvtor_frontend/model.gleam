import gleam/option.{type Option}
import namespace/namespace.{type Namespace}
import note/note.{type Note}

pub type Model {
  LoggedIn(LoggedInModel)
  Public(PublicModel)
}

pub type LoggedInModel {
  LoggedInModel(
    note_search_query: String,
    selected_note: Option(Note),
    selected_namespace: Option(Namespace),
    notes: List(Note),
    namespaces: List(Namespace),
    is_mobile_sidebar_toggled: Bool,
    new_note_content: String,
    new_note_name: String,
    edit_note_content: String,
    edit_note_name: String,
  )
}

pub type PublicModel {
  PublicModel(master_password_input: String)
}
