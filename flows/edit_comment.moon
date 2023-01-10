
db = require "lapis.db"

import with_params from require "lapis.validate"
import filter_update from require "helpers.model"

types = require "lapis.validate.types"
shapes = require "helpers.shapes"

import Flow from require "lapis.flow"

import SubmissionComments, Notifications from require "models"

class EditCommentFlow extends Flow
  validate_params: with_params {
    {"comment", types.params_shape {
      {"body", types.limited_text(1024 * 10) * -shapes.empty_html}
      {"source", types.empty + types.db_enum SubmissionComments.sources}
    }}
  }, (params) => params.comment

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

    for u in *comment\get_mentioned_users!
      Notifications\notify_for u, comment, "mention"

    comment

  edit_comment: =>
    params = @validate_params!
    filter_update @comment, params

    if next params
      params.edited_at = db.format_date!
      @comment\update params

  delete_comment: =>
    success = @comment\update { deleted: true }, where: { deleted: false }
    if success
      @comment\get_submission!\update {
        comments_count: db.raw "comments_count - 1"
      }
      true
    else
      false
