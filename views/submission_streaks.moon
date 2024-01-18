
date = require "date"

class SubmissionStreaks extends require "widgets.page"
  @needs: {
    "submission"
    "submits"
  }

  column_content: =>
    div class: "page_header", ->
      h2 "Submission's streaks"

    section ->
      p ->
        a href: @url_for(@submission), ->
          raw "&laquo; Return to submission"

    section ->
      h3 "Remove from streak"
      if next @submits
        p "Removing a submission from a streak does not delete the post, but it
        will no longer be visible on the streak's page or contribute to that
        specific streak. The post will still count for your account's personal streak counter."

        ul class: "streak_submission_list", ->
          for submit in *@submits
            streak = submit\get_streak!
            continue unless streak\allowed_to_view @current_user

            li class: "streak_submission_row", ->
              a href: @url_for(streak), streak.title
              text " for "


              unit = streak\truncate_date submit.submit_time
              unit_num = "#{streak\interval_noun false} ##{streak\unit_number_for_date(submit.submit_time)}"

              strong "#{unit_num} (#{streak\format_date_unit unit})"

              if submit\allowed_to_moderate @current_user
                form method: "post", ->
                  input type: "hidden", name: "streak_id", value: streak.id
                  @csrf_input!

                  label ->
                    input type: "checkbox", name: "confirm", value: "1", required: true
                    text " Confirm"

                  text " "

                  button name: "action", value: "unsubmit", class: "button", "Unsubmit"
      else
        p class: "em", "This submission is currently not part of any streaks. If you add it to a streak you can remove it from here."

    if @submittable_streaks and next @submittable_streaks
      section ->
        h3 "Add to streak"
        p "This will add the submission to a streak using the post's creation
        time. You can not submit a post if you have already submitted to the
        streak for that time unit."

        ul class: "streak_submission_list", ->
          for streak in *@submittable_streaks
            continue unless streak\allowed_to_view @current_user
            unit = streak\truncate_date @submission.created_at
            unit_num = "#{streak\interval_noun false} ##{streak\unit_number_for_date(@submission.created_at)}"

            late_submit = streak\current_unit_number! > streak\unit_number_for_date @submission.created_at

            li class: "streak_submission_row", ->
              a href: @url_for(streak), streak.title

              if streak\allowed_to_submit @submission\get_user!
                form method: "post", ->
                  input type: "hidden", name: "streak_id", value: streak.id
                  @csrf_input!

                  label ->
                    input type: "checkbox", name: "confirm", value: "1", required: true
                    text " Confirm"

                  text " "

                  button name: "action", value: "submit", class: "button", "Submit for #{unit_num} (#{streak\format_date_unit unit})"

                  if late_submit
                    text " "
                    em "(late submit)"


