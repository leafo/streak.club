
class UserRegister extends require "widgets.base"
  @include "widgets.form_helpers"

  inner_content: =>
    h1 "Register"

    @render_errors!

    form method: "POST", class: "form", ->
      @csrf_input!

      @text_input_row {
        label: "Username"
        name: "username"
        required: true
      }

      @text_input_row {
        label: "Email"
        name: "email"
        required: true
      }

      @text_input_row {
        label: "Password"
        name: "password"
        required: true
        type: "password"
      }

      @text_input_row {
        label: "Password again"
        name: "password_repeat"
        required: true
        type: "password"
      }

      div class: "button_row", ->
        input class: "button", type: "submit", value: "Create account"


