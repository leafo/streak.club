
import Flow from require "lapis.flow"

import assert_page from require "helpers.app"
import assert_csrf from require "helpers.csrf"
import assert_valid from require "lapis.validate"
import assert_error from require "lapis.application"

import SUBMISSIONS_PER_PAGE, render_submissions_page from require "helpers.submissions"

class StreakFlow extends Flow
  expose_assigns: true

  load_streak: (check_slug=true) =>
    assert_valid @params, {
      {"id", is_integer: true}
      {"stug", type: "string", optional: true}
    }

    import Streaks from require "models"

    @streak = assert_error Streaks\find(@params.id), "invalid streak"

    assert_error @streak\allowed_to_view @current_user
    @streak_user = @streak\has_user @current_user

    if check_slug
      if @params.slug != @streak\slug!
        assert_error @req.cmd_mth == "GET", "invalid slug"
        ps = {k, v for k,v in pairs @params}
        ps.slug = @streak\slug!

        url = if @route_name
          @url_for @route_name, ps, @GET
        else
          @url_for @streak

        @write {
          status: 301
          redirect_to: url
        }

        return nil, "invalid slug"

    @streak

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

    @setup_twitter_card!
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
    seen_submissions = {}
    out_uploads = {}

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

    for fs in *featured_submissions
      break if #out_uploads >= 4
      s = fs\get_submission!

      for upload in *s\get_uploads!
        if upload\is_image!
          seen_submissions[s.id] = true
          table.insert out_uploads, upload
          break

    for s in *@submissions
      break if #out_uploads >= 4
      continue if seen_submissions[s.id]

      for upload in *s\get_uploads!
        if upload\is_image!
          seen_submissions[s.id] = true
          table.insert out_uploads, upload
          break

    @card_images = out_uploads

