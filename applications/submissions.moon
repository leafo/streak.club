
lapis = require "lapis"

import assert_valid from require "lapis.validate"
import capture_errors, assert_error, capture_errors_json from require "lapis.application"

import not_found from require "helpers.app"
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


