
lapis = require "lapis"

import respond_to, capture_errors_json, capture_errors, assert_error from require "lapis.application"
import require_login, not_found from require "helpers.app"
import assert_valid from require "lapis.validate"
import assert_csrf from require "helpers.csrf"

import Streaks, Users from require "models"

EditStreakFlow = require "flows.edit_streak"

class UsersApplication extends lapis.Application
  [new_streak: "/streaks/new"]: require_login respond_to {
    GET: =>
      render: "edit_streak"

    POST: capture_errors_json =>
      assert_csrf @
      flow = EditStreakFlow @
      streak = flow\create_streak!

      json: {
        :streak
        url: @url_for streak
      }
  }

  [edit_streak: "/streak/:id/edit"]: require_login capture_errors {
    on_error: =>
      not_found

    respond_to {
      before: =>
        @streak = assert_error Streaks\find(@params.id), "invalid streak"
        assert_error @streak\allowed_to_edit @current_user

      GET: =>
        render: "edit_streak"

      POST: capture_errors =>
        assert_csrf @
        flow = EditStreakFlow @
        flow\edit_streak!
        @session.flash = "Streak saved"
        redirect_to: @url_for @streak
    }
  }

  [view_streak: "/streak/:id"]: capture_errors {
    on_error: =>
      not_found

    respond_to {
      before: =>
        assert_valid @params, {
          {"id", is_integer: true}
        }

        @streak = assert_error Streaks\find(@params.id), "invalid streak"
        assert_error @streak\allowed_to_view @current_user
        @streak_user = @streak\has_user @current_user

      GET: =>
        render: true

      POST: capture_errors_json =>
        assert_csrf @
        assert_valid @params, {
          {"action", one_of: {"join_streak", "leave_streak"}}
        }

        res = switch @params.action
          when "join_streak"
            if @streak\join @current_user
              @session.flash = "Streak joined"
          when "leave_streak"
            if @streak\leave @current_user
              @session.flash = "Streak left"

        redirect_to: @url_for @streak
    }
  }

  [streaks: "/streaks"]: =>
    @pager = Streaks\paginated "order by id desc", prepare_results: (streaks) ->
      Users\include_in streaks, "user_id"
      streaks

    @streaks = @pager\get_page 1
    render: true

  [new_streak_submission: "/streak/:id/submit"]: require_login capture_errors {
    on_error: => not_found
    respond_to {
      before: =>
        @streak = assert_error Streaks\find(@params.id), "invalid streak"
        assert_error @streak\allowed_to_submit @current_user

      GET: =>
        render: true

      POST: capture_errors =>
        assert_csrf @
        json: @params
    }
  }

