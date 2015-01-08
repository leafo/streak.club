
StreakList = require "widgets.streak_list"

class Streaks extends require "widgets.base"
  inner_content: =>
    div class: "page_header", ->
      h2 "Streaks"

    widget StreakList
