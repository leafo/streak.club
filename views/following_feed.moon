
SubmissionList = require "widgets.submission_list"

class FollowingFeed extends require "widgets.base"
  @needs: {"submission"}

  js_init: =>
    "S.FollowingFeed(#{@widget_selector!});"

  inner_content: =>
    div class: "page_header", ->
      h2 "Following feed"
      h3 "Submissions from everyone you follow"

    if next @submission
      widget SubmissionList
    else
      p class: "empty_message", ->
        if @current_user.following_count
          text "You're not following anyone yet"
        else
          text "None of the people you follow have posted yet"

