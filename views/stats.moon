import to_json from require "lapis.util"

class Stats extends require "widgets.base"
  @needs: {"cumulative_users"}

  js_init: =>
    data = {
      graphs: {
        cumulative_users: @cumulative_users
      }
    }

    "S.Stats(#{@widget_selector!}, #{to_json data});"

  inner_content: =>
    div class: "page_header", ->
      h2 "Stats"
      div id: "users_graph", class: "graph_container"

