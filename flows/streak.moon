
import Flow from require "lapis.flow"

import assert_page from require "helpers.app"
import assert_csrf from require "helpers.csrf"
import assert_valid from require "lapis.validate"

import SUBMISSIONS_PER_PAGE, render_submissions_page from require "helpers.submissions"

class StreakFlow extends Flow
  expose_assigns: true

  render: =>
    assert_page @
    import Submissions from require "models"
    pager = @streak\find_submissions {
      per_page: SUBMISSIONS_PER_PAGE
      prepare_submissions: (submissions) ->
        Submissions\preload_for_list submissions, {
          likes_for: @current_user
        }
    }

    @submissions = pager\get_page @page

    if @params.format == "json"
      return render_submissions_page @, SUBMISSIONS_PER_PAGE

    @title = @streak.title
    @show_welcome_banner = true
    @has_more = @streak.submissions_count > SUBMISSIONS_PER_PAGE
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

  do_streak_action: =>
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

  setup_twitter_card: =>
    -- get the submissions that have been featured in this streak
    -- get featured submissions for card
    import Submissions, FeaturedSubmissions from require "models"
    featured_submissions = FeaturedSubmissions\select "
      where submission_id in
        (select submission_id from streak_submissions where streak_id = ?)
      order by submission_id desc
      limit 8
    ", @streak.id

    FeaturedSubmissions\preload_relations featured_submissions, "submission"
    subs = [fs\get_submission! for fs in *featured_submissions]
    Submissions\preload_relations subs, "uploads"

    -- don't have enough, fill with submissions from this page...



