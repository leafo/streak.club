
StreakHeader = require "widgets.streak_header"

class StreakCalendar extends require "widgets.page"
  page_name: "calendar"

  inner_content: =>
    widget StreakHeader page_name: @page_name

    div class: "responsive_column", ->
      @column_content!

  column_content: =>
    h3 "Caldenar"

