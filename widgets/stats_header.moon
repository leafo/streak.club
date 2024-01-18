
class StatsHeader extends require "widgets.base"
  @include "widgets.tabs_helpers"

  inner_content: =>
    h2 "Global Stats"

    div class: "page_tabs", ->
      div class: "tabs_inner", ->
        @page_tab "Cumulative", "cumulative", @url_for "stats"
        @page_tab "Daily", "daily", @url_for "stats", nil, graph_type: "daily"
        @page_tab "This week", "this_week", @url_for "stats_this_week"

