
class SubmissionStreaks extends require "widgets.page"
  @needs: {
    "submission"
    "submits"
  }

  column_content: =>
    div class: "page_header", ->
      h2 "Submission's streaks"

    p "On this page you can remove a submission from a streak. The post will
    not be deleted, it will just not appear on the streak's page and count for
    that streak. The post will still count for your account's personal streak
    counter."

    unless next @submits
      p class: "em", "This submission is currently not part of any streak"

    ul class: "streak_submission_list", ->
      for submit in *@submits
        streak = submit\get_streak!
        continue unless streak\allowed_to_view @current_user

        li class: "streak_submission_row", ->
          a href: @url_for(streak), streak.title
          text " on "
          @date_format submit.submit_time

          if submit\allowed_to_moderate @current_user
            form action: "", method: "post", ->
              input type: "hidden", name: "streak_id", value: streak.id
              @csrf_input!

              label ->
                input type: "checkbox", name: "confirm", value: "1", required: true
                text " Confirm"

              text " "

              button name: "action", value: "unsubmit", class: "button", "Unsubmit"

    p ->
      a href: @url_for(@submission), ->
        raw "&laquo; Return to submission"
