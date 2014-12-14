
class Index extends require "widgets.base"
  inner_content: =>
    p ->
      a href: @url_for("user_register"), "Register"

    p ->
      a href: @url_for("user_register"), "Log in"
