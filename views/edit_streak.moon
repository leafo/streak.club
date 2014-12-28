

class EditStreak extends require "widgets.base"
  inner_content: =>
    h2 "Edit streak"

    form method: "post", ->
      div class: "input_row", ->
        label ->
          div class: "label", "Title"
          input type: "text"


      div class: "buttons", ->
        button class: "button", "Save"


