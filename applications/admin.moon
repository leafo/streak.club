
lapis = require "lapis"

import respond_to, capture_errors_json, assert_error from require "lapis.application"
import assert_valid from require "lapis.validate"

import not_found from require "helpers.app"
import assert_csrf from require "helpers.csrf"

class AdminApplication extends lapis.Application
  @path: "/admin"

  @before_filter =>
    unless @current_user and @current_user\is_admin!
      @write not_found

  [admin_featured_streak: "/feature/:id"]: respond_to {
    POST: capture_errors_json =>
      assert_csrf @

      import Streaks, FeaturedStreaks from require "models"

      streak = assert_error Streaks\find(@params.id), "invalid streak"

      assert_valid @params, {
        {"action", one_of: {"create", "delete"}}
      }

      res = switch @params.action
        when "create"
          FeaturedStreaks\create streak_id: streak.id
        when "delete"
          FeaturedStreaks\load(streak_id: streak.id)\delete!

      json: { success: true, :res }
  }
