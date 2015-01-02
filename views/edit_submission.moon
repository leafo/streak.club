

class NewStreakSubmission extends require "widgets.base"
  @include "widgets.form_helpers"

  js_init: =>

  inner_content: =>
    h2 "Submit to streak"
    p "Submitting to #{@streak.title}"

    @render_errors!

    form class: "form", method: "POST", ->
      @csrf_input!

      @text_input_row {
        label: "Title"
        name: "submission[title]"
      }

      @text_input_row {
        label: "Description"
        name: "submission[description]"
        type: "textarea"
      }

      div class: "button_row",
        button class: "button", "Submit"

