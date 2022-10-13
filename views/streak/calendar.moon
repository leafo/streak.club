
StreakHeader = require "widgets.streak_header"
StreakUnits = require "widgets.streak_units"

class StreakCalendar extends require "widgets.page"
  responsive: true
  page_name: "calendar"

  inner_content: =>
    widget StreakHeader page_name: @page_name

    div class: "responsive_column", ->
      @column_content!

  column_content: =>
    h3 "Calendar #{@year}"
    widget StreakUnits



