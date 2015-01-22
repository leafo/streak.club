class Countdown extends require "widgets.base"
  base_widget: false

  inner_content: =>
    if @header_content
      div class: "countdown_header", ->
        @header_content!

    div class: "countdown_units", ->
      for p in *{"days", "hours", "minutes", "seconds"}
        div class: "time_block", ["data-name"]: p, ->
          div class: "block_value", ""
          div class: "block_label", p

