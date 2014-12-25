
class UserRegister extends require "widgets.base"
  inner_content: =>
    h1 "Register"

    @render_errors!

    form method: "POST", class: "form", ->
      @csrf_input!

      div class: "input_row", ->
        label ->
          div class: "label", "Username"
          input type: "text", name: "username"

      div class: "input_row", ->
        label ->
          div class: "label", "Email"
          input type: "email", name: "email"

      div class: "input_row", ->
        label ->
          div class: "label", "Password"
          input type: "password", name: "password"

      div class: "input_row", ->
        label ->
          div class: "label", "Password again"
          input type: "password", name: "password_repeat"

      div class: "button_row", ->
        input class: "button", type: "submit", value: "Create account"


