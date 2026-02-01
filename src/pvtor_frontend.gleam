import gleam/dynamic/decode
import gleam/list
import gleam/bool
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import rsvp

type Model {
  Model(is_mobile_sidebar_toggled: Bool)
}

fn init(_args) -> #(Model, Effect(Msg)) {
  #(Model(is_mobile_sidebar_toggled: False), effect.none())
}

type Msg {
  UserClickedSidebarButton
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserClickedSidebarButton -> #(Model(..model, is_mobile_sidebar_toggled: !model.is_mobile_sidebar_toggled), effect.none())
  }
}

fn view_namespace_card(namespace_name: String) -> Element(Msg) {
  html.div([attribute.class("namespace-card")], [
    html.p([], [html.text(namespace_name)])
  ])
}

fn view(model: Model) -> Element(Msg) {
  let namespaces = ["Work", "Personal", "Ideas"]

  let sidebar_class = case model.is_mobile_sidebar_toggled {
    True -> "sidebar-open"
    False -> "sidebar"
  }

  html.div([attribute.class("main")], [

    html.button([
      attribute.class("mobile-menu-button"), 
      event.on_click(UserClickedSidebarButton)
    ], [html.text("☰")]),

    html.div(
      [
        attribute.class(sidebar_class)
      ],
      [
        html.div([attribute.class("sidebar-header")], [
          html.text("Pvtor Dashboard")
        ]),

        html.div([attribute.class("namespaces-section")], [
          html.text("Namespaces"),
          html.button([attribute.class("new-namespace-button")], [
            html.text("New namespace")
          ])
        ]),

        html.div([], list.map(namespaces, view_namespace_card(_))),
      ]
    ),

    html.div([attribute.class("main-content")], [
      html.div([attribute.class("top-bar")],
        [
          html.div([attribute.class("search-section")], [
            html.input([
              attribute.placeholder("Search notes..."),
              attribute.class("search-input"),
            ]),

            html.button([attribute.class("new-note-button")], [
              html.text("New note")
            ])
          ])
        ]
      ),

      html.div([attribute.class("content-area")], [
	html.text("Content area")
      ]),
    ])
  ])
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}
