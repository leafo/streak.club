
lapis = require "lapis"
db = require "lapis.db"

import
  respond_to
  capture_errors_json
  capture_errors
  assert_error
  yield_error
  from require "lapis.application"

import require_login
  not_found
  assert_unit_date
  assert_page
  parse_filters
  find_streak
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

  "/s/:id": capture_errors {
    on_error: => not_found
    =>
      find_streak @
      redirect_to: @url_for @streak
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
        @show_welcome_banner = true
        @has_more = @streak.submissions_count > SUBMISSION_PER_PAGE
        @canonical_url = @build_url @url_for @streak

        if @page and @page > 1
          @canonical_url ..= "?page=#{@page}"

        @mobile_friendly = true

        @embed_page = not not @params.embed

        if @streak_user
          if @current_submit = @streak_user\current_unit_submission!
            @current_submit\get_submission!

          @completed_units = @streak_user\get_completed_units!

        @unit_counts = @streak\unit_submission_counts!
        @streak_host = @streak\get_user!
        @streak_host.following = @streak_host\followed_by @current_user

        render: true

      POST: capture_errors_json =>
        assert_csrf @
        assert_valid @params, {
          {"action", one_of: {"join_streak", "leave_streak"}}
        }

        res = switch @params.action
          when "join_streak"
            if @streak\join @current_user
              import Notifications from require "models"
              Notifications\notify_for @streak\get_user!, @streak, "join", @current_user
              if @streak\is_members_only!
                @session.flash = "Requested to join"
              else
                @session.flash = "Streak joined"
          when "leave_streak"
            if @streak\leave @current_user
              @session.flash = "Streak left"

        redirect_to: @url_for @streak
    }
  }

  [view_streak_participants: "/s/:id/:slug/participants"]: =>
    import Followings from require "models"

    find_streak @
    check_slug @
    assert_page @

    @pager = @streak\find_participants per_page: 25
    @users = [s.user for s in *@pager\get_page @page]
    if @page != 1 and not next @users
      return redirect_to: @url_for "view_streak_participants", {
        id: @streak.id
        slug: @streak.slug
      }

    Followings\load_for_users @users, @current_user

    @title = "Participants for #{@streak.title}"

    if @page > 1
      @title = @title .. " - Page #{@page}"

    render: true

  [view_streak_unit: "/streak/:id/unit/:date"]: capture_errors {
    on_error: =>
      not_found

    =>
      import Submissions from require "models"
      find_streak @
      assert_unit_date @

      @title = "#{@streak.title} - #{@params.date}"

      @pager = @streak\find_submissions_for_unit @unit_date, {
        prepare_submissions: (submissions) ->
          Submissions\preload_for_list submissions, {
            likes_for: @current_user
          }
      }

      @submissions = @pager\get_page!
      @streak_user = @streak\find_streak_user @current_user

      if @streak_user
        @streak_submission = @streak_user\submission_for_date @unit_date

      @start_time = date @unit_date
      @end_time = @streak\increment_date_by_unit date @unit_date

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
    @show_welcome_banner = true

    @filters, has_invalid = parse_filters @params.splat, browse_filters  if @params.splat
    if has_invalid
      do return redirect_to: @url_for "streaks"

    @filters or= {}
    @title = "Browse Streaks"
    import BrowseStreaksFlow from require "flows.browse_streaks"

    flow = BrowseStreaksFlow @
    flow\browse_by_filters @filters
    render: true

  [streak_embed: "/streak/:id/embed"]: =>
    find_streak @
    @title = "Embed #{@streak.title}"
    render: true

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

      @mobile_friendly = true

      import Submissions from require "models"
      pager = @streak\find_top_submissions {
        per_page: SUBMISSION_PER_PAGE
        prepare_submissions: (submissions) ->
          Submissions\preload_for_list submissions, {
            likes_for: @current_user
          }
      }
      @submissions = pager\get_page!
      render: true
  }
