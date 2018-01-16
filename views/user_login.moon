class UserLogin extends require "widgets.page"
  @include "widgets.form_helpers"

  responsive: true

  column_content: =>
    register_url = @url_for "user_register", nil, return_to: @return_to

    div class: "page_header", ->
      h2 "Log in"

    register_message = switch @return_to_route_name
      when "community.new_topic"
        "create a new discussion"
      when "view_streak"
        "join a streak"

    if register_message
      p ->
        text "Log into your Streak.club account to #{register_message}, or "
        a href: register_url, "create an account"
        text "."

    form method: "POST", class: "form primary_form", ->
      @render_errors!

      @csrf_input!
      @text_input_row {
        label: "Username"
        name: "username"
        required: true
        mobile: true
        value: @params.username
      }

      @text_input_row {
        label: "Password"
        name: "password"
        required: true
        type: "password"
        mobile: true
      }

      div class: "button_row", ->
        input class: "button", type: "submit", value: "Log in"
        text " or "
        a href: register_url, "Create new account"
        raw " &middot; "
        a href: @url_for("user_forgot_password"), "Forgot password"

