
UserList = require "widgets.user_list"

class SubmissionLikes extends require "widgets.page"
  @needs: {"submission", "likes"}

  column_content: =>
    div class: "page_header", ->
      h2 ->
        text "Likes for "
        if @submission.title
          a href: @url_for(@submission), @submission.title
        else
          a href: @url_for(@submission), "a submission"
          text " by "
          a href: @url_for(@submission\get_user!), @submission\get_user!\name_for_display!

      h3 "Liked #{@plural @submission.likes_count, "time", "times"}"

    widget UserList {
      users: [l.user for l in *@likes]
    }


