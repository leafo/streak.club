
db = require "lapis.db"

import assert_error, yield_error from require "lapis.application"
import assert_valid from require "lapis.validate"
import trim_filter from require "lapis.util"
import filter_update from require "helpers.model"
import is_empty_html from require "helpers.html"

import Flow from require "lapis.flow"

import SubmissionComments, Notifications from require "models"

class EditCommentFlow extends Flow
  validate_params: =>
    assert_valid @params, {
      {"comment", type: "table"}
    }

    comment_params = @params.comment
    trim_filter comment_params, { "body" }

    assert_valid comment_params, {
      {"body", optional: true, max_length: 1024 * 10}
    }

    assert_error comment_params.body and not is_empty_html(comment_params.body),
      "comment can't be empty"

    comment_params

  create_comment: =>
    params = @validate_params!
    params.user_id = @current_user.id
    params.submission_id = @submission.id

    comment = SubmissionComments\create params

    @submission\update {
      comments_count: db.raw "comments_count + 1"
    }

    @current_user\update {
      comments_count: db.raw "comments_count + 1"
    }

    unless @current_user.id == @submission\get_user!.id
      Notifications\notify_for @submission\get_user!,
        @submission, "comment", comment

    comment

  edit_comment: =>
    params = @validate_params!
    filter_update @comment, params

    if next params
      params.edited_at = db.format_date!
      @comment\update params

  delete_comment: =>
    res = @comment\update deleted: true
    if res.affected_rows and res.affected_rows > 0
      @comment\get_submission!\update {
        comments_count: db.raw "comments_count - 1"
      }
      true
    else
      false
