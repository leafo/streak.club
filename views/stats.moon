StatsHeader = require "widgets.stats_header"
HomeHeader = require "widgets.home_header"

class Stats extends require "widgets.page"
  @include "widgets.tabs_helpers"

  @needs: {
    "graph_type"
    "graph_users"
    "graph_streaks"
    "graph_submissions"
    "graph_submission_comments"
    "graph_submission_likes"
  }

  @es_module: [[
    import {Stats} from "main/stats"
    new Stats(widget_selector, widget_params)
  ]]

  js_init: =>
    super {
      cumulative: @graph_type == "cumulative"
      graphs: {
        users: @graph_users
        streaks: @graph_streaks
        submissions: @graph_submissions
        submission_likes: @graph_submission_likes
        submission_comments: @graph_submission_comments
      }
    }

  inner_content: =>
    if @current_user
      widget HomeHeader page_name: @route_name == "stats_this_week" and "weekly" or "stats"

    div class: "inner_column", ->
      widget StatsHeader page_name: @graph_type
      div id: "users_graph", class: "graph_container"
      div id: "submissions_graph", class: "graph_container"
      div id: "submission_likes_graph", class: "graph_container"
      div id: "submission_comments_graph", class: "graph_container"
      div id: "streaks_graph", class: "graph_container"


