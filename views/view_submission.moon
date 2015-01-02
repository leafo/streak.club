
class ViewSubmission extends require "widgets.base"
  @needs: {"submission", "streaks"}

  inner_content: =>
    h2 @submission.title
    h3 ->
      text "A submission by "
      a href: @url_for(@user), @user\name_for_display!
      text " for "
      num_streaks = #@submission.streaks
      for i, streak in ipairs @submission.streaks
        text " "
        a href: @url_for(streak), streak.title
        text ", " unless i == num_streaks

    p @submission.description

