
lapis = require "lapis"

import respond_to, capture_errors_json from require "lapis.application"
import require_login from require "helpers.app"
import trim_filter from require "lapis.util"
import assert_valid from require "lapis.validate"

class UsersApplication extends lapis.Application
  [new_streak: "/streaks/new"]: require_login respond_to {
    GET: =>
      render: "edit_streak"

    POST: capture_errors_json =>
      assert_valid @params, {
        {"streak", type: "table"}
      }

      streak_params = @params.streak
      trim_filter streak_params, {
        "title", "description", "short_description", "start_date", "end_date"
      }

      assert_valid streak_params, {
        {"title", exists: true, max_length: 1024}
        {"short_description", exists: true, max_length: 1024 * 10}
        {"description", exists: true, max_length: 1024 * 10}
        {"start_date", exists: true, max_length: 1024}
        {"end_date", exists: true, max_length: 1024}
      }

      import Streaks from require "models"
      streak_params.rate = "daily"
      streak_params.user_id = @current_user.id

      streak = Streaks\create streak_params
      json: {
        :streak
        -- url: @url_for(streak)
      }
  }


