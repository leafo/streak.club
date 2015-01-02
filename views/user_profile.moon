
class UserProfile extends require "widgets.base"
  @needs: {"user", "submissions"}

  inner_content: =>
    h2 @user\name_for_display!
    p "A user registered #{@format_timestamp @user.created_at}"

    if next @submissions
      h2 "Submissions"

      div class: "submission_list", ->
        for submission in *@submissions
          div class: "submission_row", ->
            text submission.title


