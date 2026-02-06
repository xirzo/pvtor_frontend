import note/note.{type Note}
import namespace/namespace.{type Namespace}
import gleam/option.{type Option}
import rsvp
import varasto

pub type Msg {
  UserClickedSidebarButton
  UserClickedNoteCard(Note)
  UserClickedNamespaceCard(Namespace)
  UserUpdatedNoteSearchQuery(String)
  UserUpdatedNewNoteName(String)
  UserUpdatedNewNoteContent(String)
  UserClickedNewNoteButton
  UserClickedCreateNoteButton(String, String, Option(Int))
  ApiReturnedNotes(Result(List(Note), rsvp.Error))
  ApiReturnedCreatedNote(Result(Note, rsvp.Error))
  ApiReturnedNamespaces(Result(List(Namespace), rsvp.Error))
  LocalStorageReturnedSelectedNote(Result(Note, varasto.ReadError))
  LocalStorageReturnedSelectedNamespace(Result(Namespace, varasto.ReadError))
}
