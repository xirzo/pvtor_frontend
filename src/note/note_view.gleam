import gleam/bool
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import note/note.{type Note}
import pvtor_frontend/msg.{type Msg}

pub fn view_note_card(note: Note) -> Element(Msg) {
  html.button(
    [
      attribute.class("note-card"),
      event.on_click(msg.UserClickedNoteCard(note)),
    ],
    [
      html.p([], [html.text(note.content)]),
    ],
  )
}

fn month_name(month: Int) -> String {
  case month {
    1 -> "January"
    2 -> "February"
    3 -> "March"
    4 -> "April"
    5 -> "May"
    6 -> "June"
    7 -> "July"
    8 -> "August"
    9 -> "September"
    10 -> "October"
    11 -> "November"
    12 -> "December"
    _ -> "Unknown"
  }
}

fn day_of_week_name(year: Int, month: Int, day: Int) -> String {
  let m = case month {
    1 | 2 -> month + 12
    _ -> month
  }
  let y = case month {
    1 | 2 -> year - 1
    _ -> year
  }
  let q = day
  let k = y % 100
  let j = y / 100

  let h = { q + { 13 * { m + 1 } } / 5 + k + k / 4 + j / 4 - 2 * j } % 7

  case h {
    0 -> "Saturday"
    1 -> "Sunday"
    2 -> "Monday"
    3 -> "Tuesday"
    4 -> "Wednesday"
    5 -> "Thursday"
    6 -> "Friday"
    _ -> "Unknown"
  }
}

fn pad_zero(num: Int) -> String {
  case num < 10 {
    True -> "0" <> int.to_string(num)
    False -> int.to_string(num)
  }
}

fn format_date(date_string: String) -> String {
  let parts = string.split(date_string, "T")

  case parts {
    [date_part, time_part] -> {
      let date_components = string.split(date_part, "-")
      let time_components =
        time_part
        |> string.split(":")

      case date_components, time_components {
        [year_str, month_str, day_str], [hour_str, minute_str, ..] -> {
          let year = result.unwrap(int.parse(year_str), 0)
          let month = result.unwrap(int.parse(month_str), 0)
          let day = result.unwrap(int.parse(day_str), 0)
          let hour = result.unwrap(int.parse(hour_str), 0)
          let minute =
            string.split(minute_str, ".")
            |> list.first
            |> result.unwrap("")
            |> int.parse
            |> result.unwrap(0)

          let dow = day_of_week_name(year, month, day)
          let month_str = month_name(month)

          dow
          <> ", "
          <> int.to_string(day)
          <> " "
          <> month_str
          <> " "
          <> int.to_string(year)
          <> ", "
          <> pad_zero(hour)
          <> ":"
          <> pad_zero(minute)
        }
        _, _ -> date_string
      }
    }
    _ -> date_string
  }
}

pub fn view_card(note: Note) -> Element(Msg) {
  let creation_time = format_date(note.creation_date)
  let update_time = format_date(note.update_date)

  let namespace_id = case note.namespace_id {
    None -> "Default namespace"
    Some(namespace) -> int.to_string(namespace)
  }

  html.div([attribute.class("note-content")], [
    html.b([], [html.text("Update date")]),
    html.p([], [html.text(update_time)]),
    html.div([attribute.class("note-content-title-button-holder")], [
      html.b([], [html.text("Note content")]),
      html.button(
        [
          event.on_click(msg.UserClickedEditButton),
          attribute.class("note-content-edit-button"),
        ],
        [
          html.text("Edit"),
        ],
      ),
    ]),
    html.p([], [html.text(note.content)]),
    html.b([], [html.text("Metadata")]),
    html.p([], [html.text("Namespace Id: " <> namespace_id)]),
    html.p([], [html.text("Is hidden: " <> bool.to_string(note.is_hidden))]),
    html.p([], [html.text("Creation date: " <> creation_time)]),
  ])
}
