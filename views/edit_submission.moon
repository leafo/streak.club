

class NewStreakSubmission extends require "widgets.base"
  @include "widgets.form_helpers"

  js_init: =>

  inner_content: =>
    if @submission
      h2 "Edit submission"
    else
      h2 "Submit to streak"

    if @streak
      p "Submitting to #{@streak.title}"

    submission = @params.submission or @submission or {}

    @render_errors!

    form class: "form", method: "POST", ->
      @csrf_input!

      @text_input_row {
        label: "Title"
        name: "submission[title]"
        value: submission.title
      }

      @text_input_row {
        label: "Description"
        name: "submission[description]"
        type: "textarea"
        value: submission.description
      }

      div class: "button_row",
        button class: "button", "Submit"

