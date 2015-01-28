
import sanitize_html from require "helpers.html"
import time_ago_in_words from require "lapis.util"

class SubmissionCommentList extends require "widgets.base"
  @needs: {"comments", "submission"}

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
            can_edit = comment\allowed_to_edit @current_user
            can_delete = @current_user and @current_user.id == @submission.user_id

            if can_edit or can_delete
              div class: "comment_tools", ->
                if can_edit
                  span class: "edit_tool", ->
                    a href: "#", class: "edit_btn", "Edit"
                    raw " &middot; "

                if can_delete or can_edit
                  a href: "#", class: "delete_btn", "Delete"

            a href: user_url, comment.user\name_for_display!
            raw " &middot; "
            span class: "comment_time", title: comment.created_at, time_ago_in_words comment.created_at

          div class: "comment_body user_formatted", ->
            raw sanitize_html comment\filled_body @

