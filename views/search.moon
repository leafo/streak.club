
StreakList = require "widgets.streak_list"
UserList = require "widgets.user_list"

class Search extends require "widgets.base"
  inner_content: =>
    div class: "page_header", ->
      h2 ->
        text "Search results for "
        span class: "query", @query

    unless next @results
      p class: "empty_message", "There were no results..."


    if streaks = @results.streaks
      h3 "Streaks"
      widget StreakList streaks: streaks

    if users = @results.users
      h3 "People"
      widget UserList users: users




