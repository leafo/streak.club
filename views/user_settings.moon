class UserSettings extends require "widgets.base"
  @needs: {"user", "user_profile"}
  @include "widgets.form_helpers"

  js_init: =>
    "new S.UserSettings(#{@widget_selector!})"

  inner_content: =>
    @content_for "all_js", ->
      @include_redactor!

    div class: "page_header", ->
      h2 "Account & profile settings"

    @render_errors!

    form action: "", method: "POST", class: "form", ->
      @csrf_input!

      @text_input_row {
        label: "Display name"
        sub: "How others will see your name"
        name: "user[display_name]"
        placeholder: "Optional"
        value: @user.display_name
      }

      @text_input_row {
        label: "Website"
        name: "user_profile[website]"
        placeholder: "Optional"
      }

      @text_input_row {
        label: "Twitter"
        name: "user_profile[twitter]"
        placeholder: "Optional"
      }

      @text_input_row {
        type: "textarea"
        label: "Bio"
        sub: "A little about you and your interests, publicly visible"
        name: "user_profile[bio]"
        placeholder: "Optional"
      }

      div class: "button_row", ->
        input class: "button", type: "submit", value: "Submit"

    div class: "form", ->
      div class: "input_row", ->
        div class: "label", "Avatar"
        p ->
          text "Set avatar on "
          a href: "https://gravatar.com/", "Gravatar"


