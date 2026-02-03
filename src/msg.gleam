import note/note.{type Note}
import rsvp
import varasto

pub type Msg {
  UserClickedSidebarButton
  UserClickedNoteCard(Note)
  ApiReturnedNotes(Result(List(Note), rsvp.Error))
  LocalStorageReturnedSelectedNote(Result(Note, varasto.ReadError))
}
