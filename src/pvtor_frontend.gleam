import gleam/dynamic/decode
import gleam/list
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import rsvp

type Cat {
  Cat(id: String, url: String)
}

type Model {
  Model(total: Int, cats: List(Cat))
}

fn init(_args) -> #(Model, Effect(Msg)) {
  #(Model(total: 0, cats: []), effect.none())
}

type Msg {
  UserClickedAddCat
  UserClickedRemoveCat
  ApiReturnedCats(Result(List(Cat), rsvp.Error))
}

fn get_cat() -> Effect(Msg) {
  let decoder = {
    use id <- decode.field("id", decode.string)
    use url <- decode.field("url", decode.string)

    decode.success(Cat(id:, url:))
  }

  let url = "https://api.thecatapi.com/v1/images/search"
  let handler = rsvp.expect_json(decode.list(decoder), ApiReturnedCats)

  rsvp.get(url, handler)
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserClickedAddCat -> #(
      Model(..model, total: model.total + 1),
      get_cat()
    )

    UserClickedRemoveCat -> #(Model(total: model.total - 1, cats: list.drop(model.cats, 1)), effect.none())

    ApiReturnedCats(Ok(cats)) -> #(
      Model(..model, cats: list.append(model.cats, cats)),
      effect.none()
    )

    ApiReturnedCats(Error(_)) -> #(model, effect.none())
  }
}

fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("h-dvh flex flex-row")], [
    html.div([attribute.class("bg-blue-500 basis-2/10")], [html.text("Hello, World")]),

    html.div([attribute.class("flex flex-col basis-8/10")], [
      html.div([attribute.class("bg-red-500 basis-1/20 content-evenly px-6")],
	[
	  html.div([attribute.class("grid grid-cols-[auto_5rem] justify-stretch gap-5")], [

	    html.input([
	      attribute.placeholder("Search notes..."),
	      attribute.class("bg-yellow-500"),
	    ]),

	    html.button([attribute.class("bg-green-500")], [
	      html.text("New note")
	    ])
	  ])
	]
      ),

      html.div([attribute.class("bg-green-500 basis-19/20")], [html.text("Hello, World")]),
    ])
  ])
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}
