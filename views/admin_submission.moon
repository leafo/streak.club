
import Submissions from require "models"

class AdminSubmission extends require "widgets.base"
  @needs: {"submission"}
  @include "widgets.table_helpers"
  @include "widgets.form_helpers"

  inner_content: =>
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
        a href: @url_for("admin_user", id: user.id), "Admin"
        text ")"
      }
      {"user_rating", Submissions.user_ratings}

      "published"
      "deleted"
      "likes_count"
      "allow_comments"
      "comments_count"
    }

    h3 "Streak submissions"
    streaks = @submission\get_streaks!

    for streak in *streaks
      fieldset ->
        legend "Submission"

        form method: "post", class: "form", ->
          @csrf_input!
          input type: "hidden", name: "streak_id", value: streak.id
          input type: "hidden", name: "submission_id", value: @submission.id

          div class: "input_row", ->
            input type: "checkbox", name: "confirm", value: "true"
            button name: "action", value: "remove_submission", "Unsubmit"

        @field_table streak.streak_submission, {
          {"streak id", -> text streak.id}
          {"streak", -> a href: @url_for(streak), streak.title}
          "submit_time"
          "late_submit"
        }


        form method: "post", class: "form", ->
          @csrf_input!
          input type: "hidden", name: "streak_id", value: streak.id
          input type: "hidden", name: "submission_id", value: @submission.id

          @text_input_row {
            name: "submit[submit_time]"
            value: streak.streak_submission.submit_time
            label: "Submission time"
          }

          div class: "input_row", ->
            @checkboxes "submit", {
              {"late_submit", "Late submit"}
            }, streak.streak_submission

          button name: "action", value: "set_submit_time", "Update"

