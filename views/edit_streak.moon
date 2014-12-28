
import to_json from require "lapis.util"

class EditStreak extends require "widgets.base"
  js_init: =>
    opts = {}
    "new S.EditStreak(#{@widget_selector!}, #{to_json opts});"

  inner_content: =>
    h2 "Edit streak"

    form method: "post", ->
      div class: "input_row", ->
        label ->
          div class: "label", "Title"
          input type: "text", name: "streak[title]"

      div class: "input_row", ->
        label ->
          div class: "label", "Short description"
          input type: "text", name: "streak[short_description]"

      div class: "input_row", ->
        label ->
          div class: "label", "Description"
          textarea name: "streak[description]"



      div class: "input_row duration_row", ->
        div class: "label", ->
          text "Duration"
          span class: "sub", ->
            raw " &mdash; When does the streak start and stop"

        div ->
          label ->
            span class: "duration_label", "Start date:"
            input type: "text", class: "date_picker start_date", name: "streak[start_date]", readonly: "readonly"

          label ->
            span class: "duration_label", "End date:"
            input type: "text", class: "date_picker end_date", name: "streak[end_date]", readonly: "readonly"

          span class: "duration_summary"

      div class: "buttons", ->
        button class: "button", "Save"


