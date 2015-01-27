
lapis = require "lapis"
db = require "lapis.db"

import
  respond_to
  capture_errors_json
  capture_errors
  assert_error
  yield_error
  from require "lapis.application"

import require_login,
  not_found,
  assert_unit_date,
  assert_page
  parse_filters
  from require "helpers.app"

import assert_valid from require "lapis.validate"
import assert_csrf from require "helpers.csrf"
import assert_signed_url from require "helpers.url"
import render_submissions_page from require "helpers.submissions"

import Streaks, Users from require "models"

date = require "date"

EditStreakFlow = require "flows.edit_streak"
EditSubmissionFlow = require "flows.edit_submission"

SUBMISSION_PER_PAGE = 25

browse_filters = {
  type: {
    "visual-arts": "visual_art"
    interactive: true
    "music-and-audio": "music"
    video: true
    writing: true
    other: true
  }

  state: {
    "in-progress": true
    upcoming: true
    completed: true
  }
}

find_streak = =>
  assert_valid @params, {
    {"id", is_integer: true}
  }

  @streak = assert_error Streaks\find(@params.id), "invalid streak"
  assert_error @streak\allowed_to_view @current_user
  @streak_user = @streak\has_user @current_user
  true

check_slug = =>
  assert_error @streak, "missing streak"
  if @params.slug != @streak\slug!
    @write redirect_to: @url_for @streak
    false
  else
    true

class StreaksApplication extends lapis.Application
  [new_streak: "/streaks/new"]: require_login respond_to {
    GET: =>
      @title = "Create a Streak"
      render: "edit_streak"

    POST: capture_errors_json =>
      assert_csrf @
      flow = EditStreakFlow @
      streak = flow\create_streak!
      streak\join @current_user
      json: { url: @url_for streak }
  }

  [edit_streak: "/streak/:id/edit"]: require_login capture_errors {
    on_error: =>
      not_found

    respond_to {
      before: =>
        @streak = assert_error Streaks\find(@params.id), "invalid streak"
        assert_error @streak\allowed_to_edit @current_user

      GET: =>
        @title = "Edit '#{@streak.title}'"
        render: "edit_streak"

      POST: capture_errors_json =>
        assert_csrf @
        flow = EditStreakFlow @
        flow\edit_streak!
        @session.flash = "Streak saved"
        json: { url: @url_for @streak }
    }
  }

  [view_streak: "/s/:id/:slug"]: capture_errors {
    on_error: =>
      not_found

    respond_to {
      before: =>
        find_streak @
        check_slug @

      GET: =>
        assert_page @
        import Submissions from require "models"
        pager = @streak\find_submissions {
          per_page: SUBMISSION_PER_PAGE
          prepare_submissions: (submissions) ->
            Submissions\preload_for_list submissions, {
              likes_for: @current_user
            }
        }

        @submissions = pager\get_page @page

        if @params.format == "json"
          return render_submissions_page @, SUBMISSION_PER_PAGE

        @title = @streak.title
        @has_more = @streak.submissions_count > SUBMISSION_PER_PAGE

        import StreakUsers from require "models"
        pager = StreakUsers\paginated "where streak_id = ?", @streak.id, {
          prepare_results: (sus) ->
            Users\include_in sus, "user_id"
        }

        @streak_users = pager\get_page!

        if @streak_user
          if @current_submit = @streak_user\current_unit_submission!
            @current_submit\get_submission!

          @completed_units = @streak_user\get_completed_units!

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

      @title = "#{@streak.title} - #{@params.date}"

      pager = @streak\find_submissions_for_unit @unit_date, {
        prepare_submissions: (submissions) ->
          Submissions\preload_for_list submissions, {
            likes_for: @current_user
          }
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
        @title = "Submit URL for #{@streak.title}"
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

  "/streaks/*": (...) =>
    @route_name = "streaks"
    @app.__class\find_action(@route_name) @, ...

  [streaks: "/streaks"]: =>
    @filters, has_invalid = parse_filters @params.splat, browse_filters  if @params.splat
    if has_invalid
      do return redirect_to: @url_for "streaks"

    @filters or= {}

    clause = {
      publish_status: Streaks.publish_statuses.published
    }

    if t = @filters.type
      clause.category = Streaks.categories\for_db t

    time_clause = if s = @filters.state
      switch s
        when "in-progress"
          [[
            start_date + (hour_offset || ' hours')::interval <= now() at time zone 'utc' and
            end_date + (hour_offset || ' hours')::interval > now() at time zone 'utc'
          ]]
        when "upcoming"
          [[
            start_date + (hour_offset || ' hours')::interval > now() at time zone 'utc'
          ]]
        when "completed"
          [[
            end_date + (hour_offset || ' hours')::interval < now() at time zone 'utc'
          ]]

    @title = "Browse Streaks"
    @pager = Streaks\paginated "
      where #{db.encode_clause clause}
      #{time_clause and "and " .. time_clause or ""}
      order by users_count desc
    ", {
      per_page: 100
      prepare_results: (streaks) ->
        Users\include_in streaks, "user_id"
        streaks
    }

    @streaks = @pager\get_page 1
    render: true

