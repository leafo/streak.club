
import Submissions from require "models"

class AdminSubmission extends require "widgets.admin.page"
  @needs: {"submission", "uploads"}
  @include "widgets.table_helpers"
  @include "widgets.form_helpers"

  column_content: =>
    div class: "page_header", ->
      h2 @submission.title or "Submission #{@submission.id}"
      h3 ->
        a href: @url_for(@submission), "View submission"

    h3 "Submission"
    user = @submission\get_user!

    @field_table @submission, {
      "id", "title", "created_at", "updated_at",
      {"submitter", ->
        a href: @url_for(user), user\name_for_display!
        text " ("
        a href: @admin_url_for(user), "Admin"
        text ")"
      }
      {"user_rating", Submissions.user_ratings}

      "published"
      "deleted"
      "likes_count"
      "allow_comments"
      "comments_count"
      "hidden"
    }

    h3 "Uploads"
    for upload in *@uploads
      @field_table upload


    h3 "Streak submissions"
    streaks = @submission\get_streaks!

    for streak in *streaks
      fieldset ->
        legend "Submission"

        form method: "post", class: "form", ->
          @csrf_input!
          input type: "hidden", name: "streak_id", value: streak.id

          div class: "input_row", ->
            input type: "checkbox", name: "confirm", value: "true"
            button name: "action", value: "remove_submission", "Unsubmit"

        @field_table streak.streak_submission, {
          {"streak id", -> text streak.id}
          {"streak", ->
            a href: @url_for(streak), streak.title
            text " ("
            a href: @admin_url_for(streak), "Admin"
            text ")"
          }
          "submit_time"
          "late_submit"
          {"unit_number", -> text streak.streak_submission\unit_number! }
        }


        form method: "post", class: "form", ->
          @csrf_input!
          input type: "hidden", name: "streak_id", value: streak.id

          @text_input_row {
            name: "submit[submit_time]"
            value: streak.streak_submission.submit_time
            label: "Submission time"
          }

          div class: "input_row", ->
            @checkboxes "submit", {
              {"late_submit", "Late submit"}
            }, streak.streak_submission

          button name: "action", value: "update_submission", "Update"

