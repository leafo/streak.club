import to_json from require "lapis.util"

StatsHeader = require "widgets.stats_header"

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

    "new S.Stats(#{@widget_selector!}, #{to_json data});"

  inner_content: =>
    widget StatsHeader page_name: @graph_type

    div class: "inner_column", ->
      div id: "users_graph", class: "graph_container"
      div id: "submissions_graph", class: "graph_container"
      div id: "submission_likes_graph", class: "graph_container"
      div id: "submission_comments_graph", class: "graph_container"
      div id: "streaks_graph", class: "graph_container"


