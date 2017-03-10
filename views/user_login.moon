class UserLogin extends require "widgets.page"
  @include "widgets.form_helpers"

  column_content: =>
    div class: "page_header", ->
      h2 "Log in"

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
        a href: @url_for("user_register"), "Create new account"
        raw " &middot; "
        a href: @url_for("user_forgot_password"), "Forgot password"

