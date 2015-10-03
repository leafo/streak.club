
class SubmissionStreaks extends require "widgets.page"
  @needs: {
    "submission"
    "submits"
  }

  column_content: =>
    div class: "page_header", ->
      h2 "Submission's streaks"

    p ->
      a href: @url_for(@submission), ->
        raw "&laquo; Return to submission"

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
              button name: "action", value: "unsubmit", class: "button", "Unsubmit"


