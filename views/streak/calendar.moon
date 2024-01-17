
StreakHeader = require "widgets.streak_header"
StreakUnits = require "widgets.streak_units"

class StreakCalendar extends require "widgets.page"
  responsive: true
  page_name: "calendar"

  @es_module: [[
    $(widget_selector).has_tooltips()
  ]]

  inner_content: =>
    widget StreakHeader page_name: @page_name

    div class: "responsive_column", ->
      @column_content!

  column_content: =>
    h3 "Calendar"

    div class: "page_tabs", ->
      div class: "tabs_inner", ->
        for year in *@streak_years
          a {
            href: @url_for "streak.calendar", {
              id: @streak.id
              slug: @streak\slug!
              year: @default_year != year and year or nil
            }
            class: {
              "tab"
              active: year == @current_year
            }
          }, year

    widget StreakUnits {
      unit_iterator: @streak\each_unit_in_range @range_left, @range_right
      hide_empty: false
      order: "asc"
    }

