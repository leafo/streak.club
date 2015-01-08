
class IndexLoggedIn extends require "widgets.base"
  inner_content: =>
    p -> a href: @url_for("new_streak"), "Create a new streak"
    p -> a href: @url_for("streaks"), "Browse existing streaks"
