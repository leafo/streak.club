
class Index extends require "widgets.base"
  inner_content: =>
    if @current_user
      p ->
        a href: @url_for("new_streak"), "New streak"
    else
      p ->
        a href: @url_for("user_register"), "Register"

      p ->
        a href: @url_for("user_login"), "Log in"
