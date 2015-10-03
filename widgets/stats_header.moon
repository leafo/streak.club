HomeHeader = require "widgets.home_header"

class StatsHeader extends require "widgets.base"
  @include "widgets.tabs_helpers"

  inner_content: =>
    if @current_user
      widget HomeHeader page_name: @route_name == "stats_this_week" and "weekly" or "stats"

    div class: "responsive_column", ->
      if @current_user
        h2 "Global Stats"
      else
        div class: "page_header", ->
          br! -- w/e
          h2 "Global Stats"

      div class: "page_tabs", ->
        @page_tab "Cumulative", "cumulative", @url_for "stats"
        @page_tab "Daily", "daily", @url_for "stats", nil, graph_type: "daily"
        @page_tab "This week", "this_week", @url_for "stats_this_week"

