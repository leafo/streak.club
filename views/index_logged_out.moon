
class IndexLoggedOut extends require "widgets.base"
  inner_content: =>
    p "Streak club is a place for running creative streaks"
    p -> a href: @url_for("user_register"), "Register"
    p -> a href: @url_for("user_login"), "Log in"
