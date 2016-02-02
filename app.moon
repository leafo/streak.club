http = require "lapis.nginx.http"
with require "cloud_storage.http"
  .set http

lapis = require "lapis"

db = require "lapis.db"

import Users, UserIpAddresses from require "models"
import generate_csrf from require "helpers.csrf"

import require_login, not_found, ensure_https from require "helpers.app"
import capture_errors_json from require "lapis.application"
import assert_valid from require "lapis.validate"

date = require "date"
config = require("lapis.config").get!

class extends lapis.Application
  layout: require "views.layout"

  cookie_attributes: =>
    expires = date(true)\adddays(365)\fmt "${http}"
    "Expires=#{expires}; Path=/; HttpOnly"

  Request: require "helpers.request"

  @enable "exception_tracking"

  @include "applications.users"
  @include "applications.streaks"
  @include "applications.submissions"
  @include "applications.uploads"
  @include "applications.admin"
  @include "applications.api"
  @include "applications.search"

  @before_filter =>
    @current_user = Users\read_session @
    generate_csrf @
    UserIpAddresses\register_ip @

    if @current_user
      @current_user\update_last_active!
      @global_notifications = @current_user\unseen_notifications!

    if @session.flash
      @flash = @session.flash
      @session.flash = false

  "/console": require"lapis.console".make!

  handle_404: => not_found

  [index: "/"]: ensure_https =>
    if @current_user
      @created_streaks = @current_user\find_hosted_streaks!\get_page!
      @active_streaks = @current_user\find_participating_streaks(state: "active")\get_page!
      @completed_streaks = @current_user\find_participating_streaks(state: "completed")\get_page!
      @unseen_feed_count = @current_user\unseen_feed_count!

      render: "dashboard"
    else
      import FeaturedStreaks, FeaturedSubmissions, Streaks, Users from require "models"
      featured = FeaturedStreaks\select "order by position desc limit 4"

      Streaks\include_in featured, "streak_id"
      @featured_streaks = [f.streak for f in *featured]
      Users\include_in @featured_streaks, "user_id"

      @mobile_friendly = true

      @featured_submissions = FeaturedSubmissions\find_submissions!\get_page!

      -- filter out things that don't have image
      @featured_submissions = for sub in *@featured_submissions
        has_image = false
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
    @mobile_friendly = true

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

  [stats: "/stats"]: =>
    import Submissions, Streaks, SubmissionComments, SubmissionLikes from require "models"

    @graph_type = @params.graph_type or "cumulative"

    import cumulative_created, daily_created from require "helpers.stats"

    switch @graph_type
      when "cumulative"
        @graph_users = cumulative_created Users
        @graph_streaks = cumulative_created Streaks

        @graph_submissions = cumulative_created Submissions
        @graph_submission_comments = cumulative_created SubmissionComments
        @graph_submission_likes = cumulative_created SubmissionLikes
      when "daily"
        @graph_users = daily_created Users
        @graph_streaks = daily_created Streaks

        @graph_submissions = daily_created Submissions
        @graph_submission_comments = daily_created SubmissionComments
        @graph_submission_likes = daily_created SubmissionLikes
      else
        return not_found

    @title = "Stats #{@graph_type}"
    render: true

  [stats_this_week: "/stats/this-week"]: capture_errors_json =>
    @title = "Streak club this past week"
    import Streaks, StreakSubmissions, Submissions from require "models"

    assert_valid @params, {
      {"days", is_integer: true, optional: true}
    }

    @days = @params.days or 7
    @days = math.min 60, math.max 1, @days

    streak_fields = "id, title, user_id, membership_type, publish_status,
      category, rate, hour_offset, start_date, end_date, users_count,
      pending_users_count"

    range = db.interpolate_query "now() at time zone 'utc' - ?::interval",
      "#{@days} days"

    @active_streaks = StreakSubmissions\select "
      where submit_time > #{range}
      group by streak_id
      order by count desc
      limit 15
    ", fields: "count(*), streak_id"

    Streaks\include_in @active_streaks, "streak_id", fields: streak_fields

    @popular_submissions = Submissions\select "
      where created_at > #{range}
      order by likes_count desc
      limit 15
    "

    Users\include_in @popular_submissions, "user_id"

    @top_users = StreakSubmissions\select "
      where submit_time > #{range}
      group by user_id
      order by count desc
      limit 15
    ", fields: "count(*), user_id"

    Users\include_in @top_users, "user_id"

    @new_streaks = Streaks\select "
      where created_at > #{range} and not deleted
      order by users_count desc
      limit 25
    ", fields: streak_fields

    Users\include_in @new_streaks, "user_id"

    render: true

  [set_timezone: "/set-timezone"]: require_login capture_errors_json =>
    import assert_timezone from require "helpers.app"
    assert_timezone @params.timezone

    @current_user\update {
      last_timezone: @params.timezone
    }, timestamp: false

    json: { success: true }

