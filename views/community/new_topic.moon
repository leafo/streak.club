import Topics, Posts from require "community.models"

import to_json from require "lapis.util"

class CommunityNewTopic extends require "widgets.page"
  @include "widgets.form_helpers"
  @needs: {"category"}

  column_content: =>
    @include_redactor!
    @render_errors!

    form method: "post", class: "form", ->
      @csrf_input!

      @text_input_row {
        label: "Title"
        name: "topic[title]"
        placeholder: "Required"
        autofocus: true
      }


      @text_input_row {
        label: "Body"
        name: "topic[body]"
        type: "textarea"
        placeholder: "Required"
      }



      if @category\allowed_to_moderate @current_user
        fieldset ->
          legend "Moderator tools"

          @input_row "Options", ->
            @checkboxes "topic", {
              {"sticky", "Sticky"}
              {"locked", "Locked"}
            }

      div class: "buttons", ->
        button class: "button", "New topic"
