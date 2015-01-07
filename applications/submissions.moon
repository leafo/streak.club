
lapis = require "lapis"

import assert_valid from require "lapis.validate"
import
  respond_to
  capture_errors
  assert_error
  capture_errors_json
  from require "lapis.application"

import not_found, require_login from require "helpers.app"
import assert_csrf from require "helpers.csrf"
import Submissions from require "models"

EditSubmissionFlow = require "flows.edit_submission"

find_submission = =>
  assert_valid @params, {
    {"id", is_integer: true}
  }

  @submission = Submissions\find @params.id
  assert_error @submission, "invalid submission"

class UsersApplication extends lapis.Application
  [view_submission: "/submission/:id"]: capture_errors {
    on_error: =>
      not_found

    =>
      find_submission @
      Submissions\preload_for_list { @submission }

      @user = @submission\get_user!
      @streaks = @submission\get_streaks!
      render: true
  }

  [edit_submission: "/submission/:id/edit"]: require_login capture_errors {
    on_error: =>
      not_found

    respond_to {
      before: =>
        find_submission @
        assert_error @submission\allowed_to_edit(@current_user), "invalid submission"

      GET: =>
        @uploads = @submission\get_uploads!
        @streaks = @submission\get_streaks!
        @suggested_tags = @current_user\suggested_submission_tags!
        render: true

      POST: capture_errors_json =>
        assert_csrf @
        flow = EditSubmissionFlow @
        flow\edit_submission!
        if @params.json
          {
            json: {
              success: true
              url: @url_for @submission
            }
          }
        else
          @session.flash = "Submission updated"
          redirect_to: @url_for @submission
    }
  }

  [submission_like: "/submission/:id/like"]: require_login capture_errors_json =>
    find_submission @
    assert_csrf @

    import SubmissionLikes from require "models"
    like = SubmissionLikes\create {
      submission_id: @submission.id
      user_id: @current_user.id
    }

    @submission\refresh "likes_count"
    json: { success: not not like, count: @submission.likes_count }

  [submission_unlike: "/submission/:id/unlike"]: require_login capture_errors_json =>
    find_submission @
    assert_csrf @

    import SubmissionLikes from require "models"

    params = {
      submission_id: @submission.id
      user_id: @current_user.id
    }

    success = if f = SubmissionLikes\find params
      f\delete!
      true

    @submission\refresh "likes_count"
    json: { success: success or false, count: @submission.likes_count }

