
class AdminEmailStreak extends require "widgets.page"
  @needs: {"streak"}
  @include "widgets.form_helpers"

  js_init: =>
    "new S.AdminEmailStreak(#{@widget_selector!});"

  column_content: =>
    @content_for "all_js", ->
      @include_redactor!
      @include_js "admin.js"

    div class: "page_header", ->
      h2 "Email streak users"
      h3 ->
        a href: @url_for(@streak), @streak.title
        raw " &middot; "
        a href: @url_for("admin_streak", id: @streak.id), "Return to admin"

    form class: "form", method: "post", ->
      @csrf_input!

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
        @radio_buttons "action", {
          {"dry_run", "Dry run", "Just print email addresses this would be sent to"}
          {"preview", "Preview", "Just send the email once to the config.admin_email"}
          {"send", "Send", "Send to everyone"}
        }

      div class: "button_row", ->
        button class: "button", "Save"
