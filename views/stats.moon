import to_json from require "lapis.util"

class Stats extends require "widgets.base"
  @include "widgets.tabs_helpers"

  @needs: {
    "page_name"
    "graph_users"
    "graph_streaks"
    "graph_submissions"
    "graph_submission_comments"
    "graph_submission_likes"
  }

  js_init: =>
    data = {
      cumulative: @graph_type == "cumulative"
      graphs: {
        users: @graph_users
        streaks: @graph_streaks
        submissions: @graph_submissions
        submission_likes: @graph_submission_likes
        submission_comments: @graph_submission_comments
      }
    }

    "S.Stats(#{@widget_selector!}, #{to_json data});"

  inner_content: =>
    div class: "page_header", ->
      h2 "Stats"

    div class: "page_tabs", ->
      @page_tab "Cumulative", "cumulative", @url_for "stats"
      @page_tab "Daily", "daily", @url_for "stats", nil, graph_type: "daily"

    div id: "users_graph", class: "graph_container"
    div id: "submissions_graph", class: "graph_container"
    div id: "submission_likes_graph", class: "graph_container"
    div id: "submission_comments_graph", class: "graph_container"
    div id: "streaks_graph", class: "graph_container"


