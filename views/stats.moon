import to_json from require "lapis.util"

class Stats extends require "widgets.base"
  @needs: {"cumulative_users", "cumulative_submissions",
    "cumulative_submission_comments", "cumulative_streak_likes",
    "cumulative_streaks"}

  js_init: =>
    data = {
      graphs: {
        cumulative_users: @cumulative_users
        cumulative_streaks: @cumulative_streaks
        cumulative_submissions: @cumulative_submissions
        cumulative_submission_likes: @cumulative_submission_likes
        cumulative_submission_comments: @cumulative_submission_comments
      }
    }

    "S.Stats(#{@widget_selector!}, #{to_json data});"

  inner_content: =>
    div class: "page_header", ->
      h2 "Stats"

      div id: "users_graph", class: "graph_container"
      div id: "submissions_graph", class: "graph_container"
      div id: "submission_likes_graph", class: "graph_container"
      div id: "submission_comments_graph", class: "graph_container"
      div id: "streaks_graph", class: "graph_container"


