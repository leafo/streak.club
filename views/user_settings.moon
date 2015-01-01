class UserSettings extends require "widgets.base"
  @include "widgets.form_helpers"

  inner_content: =>
    h1 "User settings"
    @render_errors!

    form action: "", method: "POST", class: "form", ->
      @csrf_input!

      @text_input_row {
        label: "Display name"
        name: "user[display_name]"
        placeholder: "Optional"
        value: @user.display_name
      }

      div class: "button_row", ->
        input class: "button", type: "submit", value: "Submit"

