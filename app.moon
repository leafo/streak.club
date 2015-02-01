lapis = require "lapis"

import Users from require "models"
import generate_csrf from require "helpers.csrf"

import require_login, not_found from require "helpers.app"

date = require "date"
config = require("lapis.config").get!

class extends lapis.Application
  layout: require "views.layout"

  cookie_attributes: =>
    expires = date(true)\adddays(365)\fmt "${http}"
    "Expires=#{expires}; Path=/; HttpOnly"

  @enable "exception_tracking"

  @include "applications.users"
  @include "applications.streaks"
  @include "applications.submissions"
  @include "applications.uploads"
  @include "applications.admin"

  @before_filter =>
    @current_user = Users\read_session @
    generate_csrf @

    if @current_user
      @current_user\update_last_active!
      @global_notifications = @current_user\unseen_notifications!

    if @session.flash
      @flash = @session.flash
      @session.flash = false

  "/console": require"lapis.console".make!

  handle_404: => not_found

  [index: "/"]: =>
    if @current_user
      @created_streaks = @current_user\find_hosted_streaks!\get_page!
      @active_streaks = @current_user\find_participating_streaks(state: "active")\get_page!

      render: "index_logged_in"
    else
      import FeaturedStreaks, Streaks, Users from require "models"
      featured = FeaturedStreaks\select "order by position desc limit 4"

      Streaks\include_in featured, "streak_id"
      @featured_streaks = [f.streak for f in *featured]
      Users\include_in @featured_streaks, "user_id"

      @mobile_friendly = true
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
    @pager = @current_user\find_follower_submissions {
      per_page: 25
      prepare_results: (...) ->
        Submissions\preload_for_list ..., {
          likes_for: @current_user
        }
    }
    @submissions = @pager\get_page!
    render: true

  [terms: "/terms"]: =>
    render: true

  [privacy_policy: "/privacy-policy"]: =>
    render: true
