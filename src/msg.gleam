import note/note.{type Note}
import namespace/namespace.{type Namespace}
import rsvp
import varasto

pub type Msg {
  UserClickedSidebarButton
  UserClickedNoteCard(Note)
  UserClickedNamespaceCard(Namespace)
  ApiReturnedNotes(Result(List(Note), rsvp.Error))
  ApiReturnedNamespaces(Result(List(Namespace), rsvp.Error))
  LocalStorageReturnedSelectedNote(Result(Note, varasto.ReadError))
  LocalStorageReturnedSelectedNamespace(Result(Namespace, varasto.ReadError))
}
