
lapis = require "lapis"

import assert_valid from require "lapis.validate"
import
  respond_to
  capture_errors
  assert_error
  capture_errors_json
  from require "lapis.application"

import not_found, require_login, assert_unit_date from require "helpers.app"
import assert_csrf from require "helpers.csrf"
import assert_signed_url from require "helpers.url"

import Submissions from require "models"

EditSubmissionFlow = require "flows.edit_submission"

find_submission = =>
  assert_valid @params, {
    {"id", is_integer: true}
  }

  @submission = Submissions\find @params.id
  assert_error @submission, "invalid submission"

class SubmissionsApplication extends lapis.Application
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


  [new_submission: "/submit"]: require_login capture_errors {
    on_error: => not_found

    respond_to {
      before: =>
        if @params.date
          assert_signed_url @
          import Streaks from require "models"

          @streak = assert_error Streaks\find(@params.streak_id), "invalid streak"

          assert_unit_date @
          assert_error @streak\allowed_to_view @current_user

          @streak.streak_user = assert_error @streak\has_user @current_user,
            "not part of streak"

          existing = @streak.streak_user\submission_for_date @unit_date
          if existing
            @session.flash = "You've already submitted for #{@params.date}"
            return @write redirect_to: @url_for @streak

          @submittable_streaks = { @streak }
        else
          @submittable_streaks = @current_user\get_submittable_streaks!
          unless next @submittable_streaks
            @session.flash = "You don't have any available streaks"
            @write redirect_to: @url_for "index"

      GET: =>
        @title = if #@submittable_streaks == 1
          "Submit to #{@submittable_streaks[1].title}"
        else
          "New submission"

        render: "edit_submission"

      POST: capture_errors_json =>
        assert_csrf @
        flow = EditSubmissionFlow @
        submission = flow\create_submission!
        @session.flash = "Submission added"

        json: {
          success: true
          url: @url_for submission
        }

    }
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

  [delete_submission: "/submission/:id/delete"]: require_login capture_errors {
    on_error: => not_found
    respond_to {
      before: =>
        find_submission @
        assert_error @submission\allowed_to_edit(@current_user), "invalid submission"

      GET: =>
        render: true

      POST: =>
        @submission\delete!
        @session.flash = "Submission deleted"
        redirect_to: @url_for "index"
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

