
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
            h3 ->
              a href: @url_for(submission), submission.title

            h4 ->
              text "A submission for"
              num_streaks = #submission.streaks
              for i, streak in ipairs submission.streaks
                text " "
                a href: @url_for(streak), streak.title
                text ", " unless i == num_streaks

            p class: "sub", "Submitted #{@format_timestamp submission.created_at}"
            p submission.description


