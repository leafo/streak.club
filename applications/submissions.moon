
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

class UsersApplication extends lapis.Application
  [view_submission: "/submission/:id"]: capture_errors {
    on_error: =>
      not_found

    =>
      assert_valid @params, {
        {"id", is_integer: true}
      }

      @submission = Submissions\find @params.id
      @user = @submission\get_user!

      @streaks = @submission\get_streaks!
      render: true
  }


  [edit_submission: "/submission/:id/edit"]: require_login capture_errors {
    on_error: =>
      not_found

    respond_to {
      before: =>
        assert_valid @params, {
          {"id", is_integer: true}
        }

        @submission = Submissions\find @params.id
        assert_error @submission\allowed_to_edit(@current_user), "invalid submission"

      GET: =>
        render: true

      POST: capture_errors_json =>
        assert_csrf @
        json: @params
    }

  }
