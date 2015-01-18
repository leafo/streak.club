
import sanitize_html from require "helpers.html"
import time_ago_in_words from require "lapis.util"

class SubmissionCommentList extends require "widgets.base"
  @needs: {"comments"}

  content: =>
    for comment in *@comments
      user = comment.user
      user_url = @url_for user

      div {
        class: "submission_comment"
        id: "comment-#{comment.id}"
        "data-id": comment.id
      }, ->
        div class: "comment_avatar", ->
          a href: user_url, ->
            img src: comment.user\gravatar!

        div class: "comment_content", ->
          div class: "comment_head", ->
            if comment\allowed_to_edit @current_user
              div class: "comment_tools", ->
                span class: "edit_tool", ->
                  a href: "#", class: "edit_btn", "Edit"
                  raw " &middot; "
                a href: "#", class: "delete_btn", "Delete"

            a href: user_url, comment.user\name_for_display!
            raw " &middot; "
            span class: "comment_time",  time_ago_in_words comment.created_at

          div class: "comment_body user_formatted", ->
            raw sanitize_html comment.body

