
SubmissionCommentList = require "widgets.submission_comment_list"

import login_and_return_url from require "helpers.app"

class SubmissionCommenter extends require "widgets.base"
  @needs: {"submission", "submission_comments", "has_more"}

  inner_content: =>
    div class: "comment_form_outer", ->
      h3 class: "comment_header", "Post a commment"
      if @current_user
        action = @url_for "submission_new_comment", id: @submission.id
        form class: "form comment_form", method: "POST", :action, ->
          @csrf_input!

          div class: "input_wrapper", ->
            textarea name: "comment[body]", placeholder: "Your comment"

          div class: "button_row", ->
            button class: "button", "Post comment"
      else
        div class: "comment_login", ->
          a href: login_and_return_url(@), class: "button", "Log in to post a comment"

    div class: "submission_comment_list", ->
      return unless @submission_comments and next @submission_comments
      widget SubmissionCommentList comments: @submission_comments

    if @has_more
      div {
        class: "load_more_comments load_more_btn"
        "data-href": @url_for("submission_comments", id: @submission.id)
        "data-page": 1
      }, ->
        text "Load more comments"


