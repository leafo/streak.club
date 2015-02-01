
SubmissionList = require "widgets.submission_list"

class FollowingFeed extends require "widgets.base"
  @needs: {"submission"}

  js_init: =>
    "S.FollowingFeed(#{@widget_selector!});"

  inner_content: =>
    div class: "page_header", ->
      h2 "Following feed"
      h3 "Submissions from everyone you follow"

    widget SubmissionList

