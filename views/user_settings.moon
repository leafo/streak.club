MarkdownEditor = require "widgets.markdown_editor"

class UserSettings extends require "widgets.page"
  @needs: {"user", "user_profile"}
  @include "widgets.form_helpers"

  responsive: true

  @js_init: [[
    import {UserSettings} from "main/user_settings"
    new UserSettings(widget_selector)
  ]]

  column_content: =>
    h2 "Account & profile settings"

    @render_errors!

    form action: "", method: "POST", class: "form", ->
      @csrf_input!

      profile = @user_profile or {}

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
        value: profile.website
      }

      @text_input_row {
        label: "Twitter"
        name: "user_profile[twitter]"
        placeholder: "Optional"
        value: profile.twitter
      }

      @input_row "Bio", "A little about you and your interests, publicly visible", ->
        widget MarkdownEditor {
          name: "user_profile[bio]"
          placeholder: "Optional"
          value: profile.bio
        }

      div class: "button_row", ->
        input class: "button", type: "submit", value: "Submit"

    div class: "form", ->
      div class: "input_row", ->
        div class: "label", "Avatar"
        p ->
          text "Set avatar on "
          a href: "https://gravatar.com/", "Gravatar"


