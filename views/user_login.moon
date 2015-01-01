
class UserLogin extends require "widgets.base"
  @include "widgets.form_helpers"

  inner_content: =>
    h1 "Log in"

    @render_errors!

    form method: "POST", class: "form", ->
      @csrf_input!
      @text_input_row {
        label: "Username"
        name: "username"
        required: true
      }

      @text_input_row {
        label: "Password"
        name: "password"
        required: true
        type: "password"
      }

      div class: "button_row", ->
        input class: "button", type: "submit", value: "Submit"

