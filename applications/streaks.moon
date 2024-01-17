lapis = require "lapis"

import
  respond_to
  capture_errors_json
  capture_errors
  assert_error
  from require "lapis.application"

import require_login
  not_found
  assert_unit_date
  assert_page
  find_streak
  with_csrf
  from require "helpers.app"

import with_params from require "lapis.validate"
import assert_signed_url from require "helpers.url"
import SUBMISSIONS_PER_PAGE, render_submissions_page from require "helpers.submissions"

types = require "lapis.validate.types"
shapes = require "helpers.shapes"

import Streaks, Users from require "models"

date = require "date"

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

    POST: capture_errors_json with_csrf =>
      streak = @flow("edit_streak")\create_streak!
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

      POST: capture_errors_json with_csrf =>
        @flow("edit_streak")\edit_streak!
        @session.flash = "Streak saved"
        json: { url: @url_for @streak }
    }
  }

  "/s/:id": capture_errors {
    on_error: => not_found
    =>
      -- no slug, causes redirect
      @flow("streak")\load_streak!
      nil
  }

  [view_streak: "/s/:id/:slug"]: respond_to {
    on_error: =>
      not_found

    before: =>
      find_streak @
      check_slug @

    GET: =>
      @flow("streak")\render!

    POST: capture_errors_json =>
      @flow("streak")\do_streak_action!
  }

  ["streak.calendar": "/s/:id/:slug/calendar(/:year[%d])"]: capture_errors {
    on_error: => not_found

    with_params {
      {"year", types.empty + shapes.integer * types.range(2014, 2214) }
    }, (params) =>
      @flow("streak")\load_streak!

      years = [year for year in @streak\each_year!]
      assert_error next(years), "Streak has no valid year duration"

      @streak_years = [table.remove(years) for _ in *years]
      @default_year = unpack @streak_years

      @unit_counts = @streak\unit_submission_counts!
      if @streak_user
        @completed_units = @streak_user\get_completed_units!

      if params.year == @default_year
        -- default year doesn't need to be manually specified
        return redirect_to: @url_for "streak.calendar", {
          id: @streak.id
          slug: @streak\slug!
        }

      year = params.year or @default_year

      start = @streak\start_datetime!
      stop = @streak\end_datetime!

      assert_error year >= start\getdate!, "invalid year"
      assert_error year <= (stop and stop\getdate! or date(true)\getdate!), "invalid year"

      @current_year = year
      @title = "Year #{@current_year} calendar for #{@streak.title}"

      -- compute date ranges in UTC
      @range_left = date @current_year, 1, 1
      @range_right = @range_left\copy!\addyears 1

      streak_start = @streak\start_datetime!
      if streak_start > @range_left
        @range_left = streak_start

      streak_end = @streak\end_datetime! or date true
      if streak_end < @range_right
        @range_right = streak_end

      assert @range_left and @range_right and @range_left < @range_right,
        "Failed to calculate ranges for calendar year"

      render: true
  }

  [streak_participants: "/s/:id/:slug/participants"]: respond_to {
    on_error: => not_found

    before: =>
      find_streak @
      check_slug @

    POST: capture_errors_json with_csrf with_params {
      {"action", types.one_of {"approve_member"}}
      {"user_id", types.db_id}
    }, (params) =>
      switch params.action
        when "approve_member"
          assert_error params.user_id, "missing user id"
          import StreakUsers from require "models"

          su = StreakUsers\find {
            user_id: params.user_id
            streak_id: @streak.id
          }

          assert_error su, "invalid user"
          assert_error su.pending, "invalid user"
          su\update pending: false

          import Notifications from require "models"
          Notifications\notify_for su\get_user!, @streak, "approve_join"

          @streak\recount "pending_users_count"
          @session.flash = "Approved member"

      redirect_to: @url_for "streak_participants", id: @streak.id, slug: @streak\slug!

    GET: =>
      import Followings from require "models"

      assert_page @

      @pager = @streak\find_participants {
        per_page: 25
        pending: if @streak\is_members_only! then false
      }

      @users = [s.user for s in *@pager\get_page @page]
      if @page != 1 and not next @users
        return redirect_to: @url_for "streak_participants", {
          id: @streak.id
          slug: @streak.slug
        }

      Followings\load_for_users @users, @current_user

      @title = "Participants for #{@streak.title}"

      if @streak\is_members_only! and @streak\allowed_to_edit(@current_user)
        @pending_users = @streak\find_participants({
          per_page: 100
          pending: true
        })\get_page!

        @pending_users = [su.user for su in *@pending_users]

      if @page > 1
        @title = @title .. " - Page #{@page}"

      render: true
  }

  [view_streak_unit: "/streak/:id/unit/:date"]: capture_errors {
    on_error: =>
      not_found

    =>
      import Submissions from require "models"
      find_streak @
      assert_unit_date @

      @canonical_url = @build_url @url_for "view_streak_unit", id: @params.id, date: @params.date

      @title = "#{@streak.title} - #{@params.date}"

      prepare_submissions = (submissions) ->
        Submissions\preload_for_list submissions, {
          likes_for: @current_user
        }

      @pager = @streak\find_submissions_for_unit @unit_date, :prepare_submissions
      @submissions = @pager\get_page!
      @streak_user = @streak\find_streak_user @current_user

      if @streak_user
        @streak_submission = @streak_user\submission_for_date @unit_date

      @start_time = date @unit_date
      @end_time = @streak\increment_date_by_unit date @unit_date

      if user_id = tonumber @params.user_id
        found_submission = false
        -- see if they have a submission in results, move to top
        for i, sub in ipairs @submissions
          if sub.user_id == user_id
            table.remove @submissions, i
            table.insert @submissions, 1, sub
            found_submission = true
            break

        if not found_submission and #@submissions > 0
          user_submission = @streak\find_submissions_for_unit @unit_date, {
            :prepare_submissions
            where: {
              user_id: user_id
            }
          }

          user_submission = unpack user_submission\get_page!
          if user_submission
            table.insert @submissions, 1, user_submission

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
        -- TODO: when streak has more than 200 members this fails
        @users = @streak\find_users!\get_page!
        render: true

      POST: with_csrf with_params {
        {"user_id", types.db_id}
      }, (params) =>
        import StreakUsers from require "models"
        @streak_user = StreakUsers\find {
          streak_id: @streak.id
          user_id: params.user_id
        }

        assert_error @streak_user, "invalid user"
        @submit_url = @build_url @streak_user\submit_url @, @params.date
        render: true
    }

  }

  [streaks: "/streaks(/*)"]: =>
    @show_welcome_banner = true

    flow = @flow "browse_streaks"

    @filters, has_invalid = flow\parse_filters!

    if has_invalid
      return redirect_to: @url_for "streaks"

    @title = flow\filtered_title @filters
    flow\browse_by_filters @filters

    render: true

  [streak_embed: "/streak/:id/embed"]: capture_errors {
    on_error: => not_found
    =>
      find_streak @
      @title = "Embed #{@streak.title}"
      render: true
  }

  [streak_stats: "/s/:id/:slug/stats"]: capture_errors {
    on_error: => not_found

    =>
      find_streak @
      check_slug @

      import cumulative_created from require "helpers.stats"
      import StreakSubmissions, StreakUsers from require "models"

      @cumulative_users = cumulative_created StreakUsers, {
        streak_id: @streak.id
      }

      @cumulative_submissions = cumulative_created StreakSubmissions, {
        streak_id: @streak.id
      }, "submit_time"

      render: true
  }

  [streak_top_participants: "/s/:id/:slug/top-streaks"]: capture_errors {
    on_error: => not_found
    =>
      find_streak @
      check_slug @
      @title = "Top streaks of #{@streak.title}"

      -- todo: none of these queries have indexes
      @active_top_streak_users = @streak\find_longest_active_streakers!\get_page!
      @top_streak_users = @streak\find_longest_streakers!\get_page!

      import Followings from require "models"
      for sus in *{@active_top_streak_users, @top_streak_users}
        Followings\load_for_users [su.user for su in *sus], @current_user

      render: true
  }

  [streak_top_submissions: "/s/:id/:slug/top-submissions"]: capture_errors {
    on_error: => not_found
    =>
      find_streak @
      check_slug @

      import Submissions from require "models"
      pager = @streak\find_top_submissions {
        per_page: SUBMISSIONS_PER_PAGE
        prepare_submissions: (submissions) ->
          Submissions\preload_for_list submissions, {
            likes_for: @current_user
          }
      }
      @submissions = pager\get_page!
      render: true
  }
