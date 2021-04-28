
SubmissionList = require "widgets.submission_list"
HomeHeader = require "widgets.home_header"

class FollowingFeed extends require "widgets.page"
  @needs: {"submission"}

  responsive: true

  js_init: =>
    "new S.FollowingFeed(#{@widget_selector!});"

  inner_content: =>
    widget HomeHeader page_name: "following_feed"

    div class: "responsive_column", ->
      @column_content!

  column_content: =>
    h3 "Submissions from everyone you follow"

    if next @submissions
      widget SubmissionList
    else
      p class: "empty_message", ->
        if @current_user.following_count == 0
          text "You're not following anyone yet"
        else
          text "None of the people you follow have posted yet"

