http = require "lapis.nginx.http"
with require "cloud_storage.http"
  .set http

lapis = require "lapis"

db = require "lapis.db"

import Users, UserIpAddresses from require "models"
import generate_csrf from require "helpers.csrf"

import require_login, not_found, redirect_for_https from require "helpers.app"
import capture_errors_json from require "lapis.application"
import with_params from require "lapis.validate"

types = require "lapis.validate.types"

date = require "date"
config = require("lapis.config").get!

logger = require "lapis.logging"
old_query = logger.query
logger.query = (q, time, ...) ->
  if ngx and ngx.ctx.query_log
    if config._name == "development"
      table.insert ngx.ctx.query_log, {debug.traceback(q, 3), time}
    else
      table.insert ngx.ctx.query_log, {q, time}

  old_query q, time, ...

class extends lapis.Application
  layout: require "views.layout"

  cookie_attributes: =>
    expires = date(true)\adddays(365)\fmt "${http}"
    attr = "Expires=#{expires}; Path=/; HttpOnly"
    attr ..= "; Secure" if config.enable_https
    attr

  Request: require "helpers.request"

  @enable "exception_tracking"

  @include "applications.users"
  @include "applications.streaks"
  @include "applications.submissions"
  @include "applications.uploads"
  @include "applications.admin"
  @include "applications.api"
  @include "applications.search"
  @include "applications.community"

  @before_filter =>
    return if redirect_for_https @

    if ngx and ngx.ctx
      ngx.ctx.query_log = {}

    if config.force_login_user
      @current_user = Users\find slug: config.force_login_user
    else
      @current_user = Users\read_session @

    @csrf_token = generate_csrf @
    UserIpAddresses\register_ip @

    if @current_user
      @res\add_header "Cache-Control", "no-store"
      @current_user\update_last_active!
      @global_notifications = @current_user\unseen_notifications!

    if @session.flash
      @flash = @session.flash
      @session.flash = false

  "/console": require"lapis.console".make!

  handle_404: => not_found

  [index: "/"]: =>
    if @current_user
      return @flow("dashboard")\render!

    import FeaturedStreaks, FeaturedSubmissions, Streaks, Users from require "models"
    featured = FeaturedStreaks\select "order by position desc limit 4"

    Streaks\include_in featured, "streak_id"
    @featured_streaks = [f.streak for f in *featured]
    Users\include_in @featured_streaks, "user_id"

    @featured_submissions = FeaturedSubmissions\find_submissions!\get_page!

    -- filter out things that don't have image
    @featured_submissions = for sub in *@featured_submissions
      has_image = false
      continue unless sub.uploads
      for upload in *sub.uploads
        has_image = true if upload\is_image!
        break if has_image

      continue unless has_image
      sub

    render: "index_logged_out"

  [notifications: "/notifications"]: require_login =>
    import Notifications from require "models"

    @old_notifications = Notifications\select "
      where user_id = ? and seen
      order by id desc
      limit 10
    ", @current_user.id

    all = {}

    for n in *@global_notifications
      table.insert all, n

    for n in *@old_notifications
      table.insert all, n

    Notifications\preload_objects all

    for n in *@global_notifications
      n\mark_seen!

    render: true

  [following_feed: "/feed"]: require_login =>
    import Submissions from require "models"

    @pager = @current_user\find_follower_submissions {
      per_page: 25
      prepare_results: (...) ->
        Submissions\preload_for_list ..., {
          likes_for: @current_user
        }
    }
    @submissions = @pager\get_page!
    if first = @submissions[1]
      @current_user\update_seen_feed first.created_at

    render: true

  [terms: "/terms"]: =>
    render: true

  [privacy_policy: "/privacy-policy"]: =>
    render: true

  [stats: "/stats"]: capture_errors_json with_params {
    {"graph_type", types.empty / "cumulative" + types.one_of {"cumulative", "daily"}}
  }, (params) =>
    import Submissions, Streaks, SubmissionComments, SubmissionLikes from require "models"

    @graph_type = params.graph_type

    import cumulative_created, daily_created from require "helpers.stats"

    user_filter = db.clause {
      {"(flags & ?) = 0", Users.flags.spam}
      {"(flags & ?) = 0", Users.flags.suspended}
    }

    streaks_filter = db.clause {
      {"exists(select 1 from users where users.id = streaks.user_id and ?)", user_filter}
    }

    switch @graph_type
      when "cumulative"
        @graph_users = cumulative_created Users, user_filter
        @graph_streaks = cumulative_created Streaks, streaks_filter

        @graph_submissions = cumulative_created Submissions
        @graph_submission_comments = cumulative_created SubmissionComments
        @graph_submission_likes = cumulative_created SubmissionLikes
      when "daily"
        @graph_users = daily_created Users, user_filter
        @graph_streaks = daily_created Streaks

        @graph_submissions = daily_created Submissions
        @graph_submission_comments = daily_created SubmissionComments
        @graph_submission_likes = daily_created SubmissionLikes
      else
        return not_found

    @title = "Stats #{@graph_type}"
    render: true

  [stats_this_week: "/stats/this-week"]: capture_errors_json with_params {
    {"days", types.one_of {
      types.empty / 7
      (types.db_id * types.range(1,60))\describe "Day range 1 to 60"
    }}
  }, (params) =>
    @title = "Streak club this past week"
    import Streaks, StreakSubmissions, Submissions from require "models"

    @days = params.days

    streak_fields = "id, title, user_id, membership_type, publish_status,
      category, rate, hour_offset, start_date, end_date, users_count,
      pending_users_count"

    range = db.interpolate_query "now() at time zone 'utc' - ?::interval",
      "#{@days} days"

    @active_streaks = StreakSubmissions\select "
      where submit_time > #{range} and exists(select 1 from visible_users where visible_users.id = user_id)
      group by streak_id
      order by count desc
      limit 15
    ", fields: "count(*), streak_id"

    Streaks\include_in @active_streaks, "streak_id", fields: streak_fields

    @popular_submissions = Submissions\select "
      where created_at > #{range} and exists(select 1 from visible_users where visible_users.id = user_id)
      order by likes_count desc
      limit 15
    "

    Users\include_in @popular_submissions, "user_id"

    @top_users = StreakSubmissions\select "
      where submit_time > #{range} and exists(select 1 from visible_users where visible_users.id = user_id)
      group by user_id
      order by count desc
      limit 15
    ", fields: "count(*), user_id"

    Users\include_in @top_users, "user_id"

    @new_streaks = Streaks\select "
      where created_at > #{range} and not deleted and exists(select 1 from visible_users where visible_users.id = user_id)
      order by users_count desc
      limit 25
    ", fields: streak_fields

    Users\include_in @new_streaks, "user_id"

    render: true

  [set_timezone: "/set-timezone"]: require_login capture_errors_json with_params {
    {"timezone", types.trimmed_text}
  }, (params) =>
    import assert_timezone from require "helpers.app"
    assert_timezone params.timezone

    if params.timezone != @current_user.last_timezone
      @current_user\update {
        last_timezone: params.timezone
      }, timestamp: false

      @current_user\refresh_spam_scan!

    json: { success: true }

