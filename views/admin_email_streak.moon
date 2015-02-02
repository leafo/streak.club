
class AdminEmailStreak extends require "widgets.base"
  @needs: {"streak"}
  @include "widgets.form_helpers"

  js_init: =>
    "new S.AdminEmailStreak(#{@widget_selector!});"

  inner_content: =>
    @content_for "all_js", ->
      @include_redactor!
      @include_js "admin.js"

    div class: "page_header", ->
      h2 "Email streak users"
      h3 ->
        a href: @url_for(@streak), @streak.title

    form class: "form", method: "post", ->
      @text_input_row {
        label: "Subject"
        name: "email[subject]"
      }

      @text_input_row {
        type: "textarea"
        label: "Body"
        name: "email[body]"
      }

      @input_row "Options", ->
        @radio_buttons "email[action]", {
          {"dry_run", "Dry run"}
          {"preview", "Preview"}
          {"send", "Send"}
        }

      div class: "button_row", ->
        button class: "button", "Save"
