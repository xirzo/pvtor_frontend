import lustre
import pvtor_frontend/update
import pvtor_frontend/view

pub fn main() {
  let app = lustre.application(update.init, update.update, view.view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}
// TODO: sort notes by creation/update date (by default)
// TODO: note deletion
// TODO: mark note as hidden button
// TODO: option for showing hidden notes
// TODO: add different sorting options (by creation/update date, name, ascending/descending)
// TODO: namespace creation
