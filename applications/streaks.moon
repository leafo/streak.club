
lapis = require "lapis"

import respond_to, capture_errors_json, capture_errors, assert_error, yield_error from require "lapis.application"
import require_login, not_found from require "helpers.app"
import assert_valid from require "lapis.validate"
import assert_csrf from require "helpers.csrf"
import assert_signed_url from require "helpers.url"

import Streaks, Users from require "models"

EditStreakFlow = require "flows.edit_streak"
EditSubmissionFlow = require "flows.edit_submission"

find_streak = =>
  assert_valid @params, {
    {"id", is_integer: true}
  }

  @streak = assert_error Streaks\find(@params.id), "invalid streak"
  assert_error @streak\allowed_to_view @current_user
  @streak_user = @streak\has_user @current_user
  true

assert_unit_date = =>
  y, m, d = assert_error @params.date\match("%d+-%d+-%d+"), "invalid date"
  @unit_date = date @params.date
  assert_error @streak\date_in_streak(@unit_date), "invalid date"

class StreaksApplication extends lapis.Application
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

      POST: capture_errors_json =>
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
      before: find_streak

      GET: =>
        import StreakUsers from require "models"
        pager = StreakUsers\paginated "where streak_id = ?", @streak.id, {
          prepare_results: (sus) ->
            Users\include_in sus, "user_id"
        }

        @streak_users = pager\get_page!

        if @streak_user
          if @current_submit = @streak_user\current_unit_submission!
            @current_submit\get_submission!
          @completed_units = @streak_user\completed_units!

        @unit_counts = @streak\unit_submission_counts!
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

  [view_streak_unit: "/streak/:id/unit/:date"]: capture_errors {
    on_error: =>
      not_found

    =>
      import Submissions from require "models"
      find_streak @
      assert_unit_date @

      pager = @streak\find_submissions_for_unit @unit_date, {
        prepare_submissions: Submissions\preload_for_list
      }

      @submissions = pager\get_page!

      render: true
  }

  [streak_unit_submit_url: "/streak/:id/unit/:date/submit-url"]: capture_errors {
    on_error: =>
      not_found

    respond_to {
      before: =>
        find_streak @
        assert_unit_date @
        assert_error @streak\allowed_to_edit(@current_user), "invalid streak"

      GET: =>
        @users = @streak\find_users!\get_page!
        render: true

      POST: =>
        assert_csrf @
        assert_valid @params, {
          {"user_id", is_integer: true}
        }

        import StreakUsers from require "models"
        @streak_user = StreakUsers\find {
          streak_id: @streak.id
          user_id: @params.user_id
        }

        assert_error @streak_user, "invalid user"
        @submit_url = @build_url @streak_user\submit_url @, @params.date
        render: true
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
        find_streak @

        if @params.date
          assert_error @streak\allowed_to_submit @current_user, false
          assert_signed_url @
          assert_unit_date @
          existing = @streak_user\submission_for_date @unit_date
          if existing
            @session.flash = "You've already submitted for #{@params.date}"
            return @write redirect_to: @url_for @streak

          if @params.expires and tonumber(@params.expires) < os.time!
            yield_error "url expired"

        else
          assert_error @streak\allowed_to_submit @current_user

      GET: =>
        render: "edit_submission"

      POST: capture_errors_json =>
        assert_csrf @
        flow = EditSubmissionFlow @

        json: {
          flow\create_submission!
        }
    }
  }

