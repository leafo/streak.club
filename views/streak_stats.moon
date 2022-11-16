
import to_json from require "lapis.util"
StreakHeader = require "widgets.streak_header"

class StreakStats extends require "widgets.page"
  page_name: "stats"

  @js_init: [[
    import {StreakStats} from "main/streak_stats"
    new StreakStats(widget_selector, widget_params)
  ]]

  js_init: =>
    super {
      graphs: {
        cumulative_users: @cumulative_users
        cumulative_submissions: @cumulative_submissions
      }
    }

  inner_content: =>
    widget StreakHeader page_name: @page_name

    div class: "responsive_column", ->
      @column_content!

  column_content: =>
    div id: "users_graph", class: "graph_container"
    div id: "submissions_graph", class: "graph_container"

