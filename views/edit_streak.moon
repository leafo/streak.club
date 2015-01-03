
import to_json from require "lapis.util"
date = require "date"

class EditStreak extends require "widgets.base"
  @include "widgets.form_helpers"

  js_init: =>
    opts = {
      streak: {
        hour_offset: @streak.hour_offset
      }
    }
    "new S.EditStreak(#{@widget_selector!}, #{to_json opts});"

  inner_content: =>
    if @streak
      h2 "Edit streak"
    else
      h2 "New streak"

    @render_errors!

    streak = @params.streak or @streak or {}

    form method: "post", class: "form", ->
      @csrf_input!
      input type: "hidden", name: "timezone", value: "", class: "timezone_input"

      @text_input_row {
        label: "Title"
        name: "streak[title]"
        value: streak.title
      }

      @text_input_row {
        label: "Short description"
        sub: "A single line describing the streak"
        name: "streak[short_description]"
        value: streak.short_description
      }

      @text_input_row {
        type: "textarea"
        label: "Description"
        name: "streak[description]"
        value: streak.description
      }

      div class: "input_row duration_row", ->
        div class: "label", ->
          text "Duration"
          span class: "sub", ->
            raw " &mdash; When does the streak start and stop"

        div ->
          label ->
            span class: "duration_label", "Start date:"
            input {
              type: "text"
              class: "date_picker start_date"
              name: "streak[start_date]"
              readonly: "readonly"
              value: @format_date_for_input streak.start_date
            }

          label ->
            span class: "duration_label", "End date:"
            input {
              type: "text"
              class: "date_picker end_date"
              name: "streak[end_date]"
              readonly: "readonly"
              value: @format_date_for_input streak.end_date
            }

          span class: "duration_summary"

      @text_input_row {
        label: "Roll over hour"
        sub: "Hour in day when streak rolls over to next day, local timezone, 24 hour time"
        name: "streak[hour_offset]"
        class: "hour_offset_input"
        value: ""
      }

      div class: "buttons", ->
        button class: "button", "Save"

  format_date_for_input: (timestamp) =>
    return unless timestamp
    date(timestamp)\fmt "%m/%d/%Y"

