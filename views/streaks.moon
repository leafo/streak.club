

class Streaks extends require "widgets.base"
  inner_content: =>
    h2 "Streaks"
    div class: "streak_list", ->
      for streak in *@streaks
        div class: "streak_row", ->
          h3 ->
            a href: "", streak.title
          h4 streak.short_description

          p ->
            a href: "", "Edit"

