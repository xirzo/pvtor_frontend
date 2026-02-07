import lustre
import pvtor_frontend/update
import pvtor_frontend/view

pub fn main() {
  let app = lustre.application(update.init, update.update, view.view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}
// TODO: namespace creation
// TODO: note deletion
// TODO: option for showing hidden notes
// TODO: sort notes by creation/update date
// TODO: add different sorting options
