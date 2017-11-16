
class UserForgotPassword extends require "widgets.page"
  @include "widgets.form_helpers"

  responsive: true

  column_content: =>
    div class: "page_header", ->
      h2 "Reset password"

    if @profile
      @reset_form!
    else
      @email_form!

  reset_form: =>
    p "Enter a new password for #{@user\name_for_display!}."
    form method: "POST", class: "form primary_form", ->
      @render_errors!
      @csrf_input!

      @text_input_row {
        type: "password"
        name: "password"
        label: "Password"
      }

      @text_input_row {
        type: "password"
        name: "password_repeat"
        label: "Password again"
      }

      div class: "button_row", ->
        input class: "button", type: "submit", value: "Update password"

  email_form: =>
    p "Enter your email address to be sent a password reset link."

    form method: "POST", class: "form primary_form", ->
      @render_errors!
      @csrf_input!

      @text_input_row {
        label: "Email"
        name: "email"
        required: true
      }

      div class: "button_row", ->
        input class: "button", type: "submit", value: "Send password reset"

