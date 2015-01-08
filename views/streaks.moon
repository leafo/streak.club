
StreakList = require "widgets.streak_list"

class Streaks extends require "widgets.base"
  inner_content: =>
    h2 "Streaks"
    widget StreakList
