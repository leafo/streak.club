
import sanitize_html from require "helpers.html"
import time_ago_in_words from require "lapis.util"

class SubmissionCommentList extends require "widgets.base"
  @needs: {"comments"}

  content: =>
    for comment in *@comments
      user = comment.user
      user_url = @url_for user

      div class: "submission_comment", ->
        div class: "comment_avatar", ->
          a href: user_url, ->
            img src: comment.user\gravatar!

        div class: "comment_content", id: "comment-#{comment.id}", ->
          div class: "comment_head", ->
            a href: user_url, comment.user\name_for_display!
            raw " &middot; "
            span class: "comment_time",  time_ago_in_words comment.created_at

          div class: "comment_body user_formatted", ->
            raw sanitize_html comment.body

