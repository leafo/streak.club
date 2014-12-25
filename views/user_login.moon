
class UserLogin extends require "widgets.base"
  inner_content: =>
    h1 "Log in"

    @render_errors!

    form method: "POST", class: "form", ->
      @csrf_input!

      div class: "input_row", ->
        label ->
          div class: "label", "Username"
          input type: "text", name: "username"

      div class: "input_row", ->
        label ->
          div class: "label", "Password"
          input type: "password", name: "password"

      div class: "button_row", ->
        input class: "button", type: "submit", value: "Submit"

