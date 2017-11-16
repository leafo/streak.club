HomeHeader = require "widgets.home_header"

class UserSettings extends require "widgets.page"
  @needs: {"user", "user_profile"}
  @include "widgets.form_helpers"

  js_init: =>
    "new S.UserSettings(#{@widget_selector!})"

  inner_content: =>
    widget HomeHeader page_name: "settings"

    div class: "inner_column", ->
      @column_content!

  column_content: =>
    @content_for "all_js", ->
      @include_redactor!

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

      @text_input_row {
        type: "textarea"
        label: "Bio"
        sub: "A little about you and your interests, publicly visible"
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


