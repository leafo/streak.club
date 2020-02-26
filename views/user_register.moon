
class UserRegister extends require "widgets.page"
  @include "widgets.form_helpers"

  responsive: true

  column_content: =>
    div class: "page_header", ->
      h2 "Sign up"

    form method: "POST", class: "form primary_form", ->
      @render_errors!
      @csrf_input!

      @text_input_row {
        label: "Username"
        name: "username"
        required: true
        mobile: true
        autofocus: true
        autocomplete: "username"
        value: @params.username
      }

      @text_input_row {
        label: "Email"
        name: "email"
        required: true
        value: @params.email
      }

      @text_input_row {
        label: "Password"
        name: "password"
        autocomplete: "new-password"
        required: true
        type: "password"
      }

      @text_input_row {
        label: "Password again"
        name: "password_repeat"
        autocomplete: "new-password"
        required: true
        type: "password"
      }

      div class: "input_row terms_row", ->
        label ->
          input type: "checkbox", name: "accept_terms", value: "yes", checked: @params.accept_terms
          text "I accept the "
          a href: @url_for"terms", target: "_blank", "Terms of Service"

      div class: "button_row", ->
        input class: "button", type: "submit", value: "Create account"
        text " or "
        a href: @url_for("user_login", nil, return_to: @return_to), "Log in to existing account"
        raw " &middot; "
        a href: @url_for("user_forgot_password"), "Forgot password"


