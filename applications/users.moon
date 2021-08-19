
lapis = require "lapis"
db = require "lapis.db"

import
  respond_to, capture_errors, assert_error, capture_errors_json
  from require "lapis.application"

import assert_valid from require "lapis.validate"
import trim_filter, slugify from require "lapis.util"

import Users, Uploads, Submissions, Streaks, StreakUsers from require "models"

import not_found, require_login, assert_page from require "helpers.app"
import assert_csrf from require "helpers.csrf"
import render_submissions_page, SUBMISSIONS_PER_PAGE from require "helpers.submissions"

config = require("lapis.config").get!

find_user = =>
  @user = if @params.id
    assert_valid @params, {
      {"id", is_integer: true}
    }
    Users\find @params.id
  elseif @params.slug
    Users\find slug: slugify @params.slug

  assert_error @user, "invalid user"
  assert_error @user\allowed_to_view(@current_user), "invalid user"

class UsersApplication extends lapis.Application
  [user_profile: "/u/:slug"]: capture_errors {
    on_error: => not_found
    =>
      find_user @
      assert_page @

      @user_profile = @user\get_user_profile!

      pager = @user\find_submissions {
        show_hidden: @current_user and
          (@current_user\is_admin! or @current_user.id == @user.id)

        per_page: SUBMISSIONS_PER_PAGE
        prepare_results: (...) ->
          Submissions\preload_for_list ..., {
            likes_for: @current_user
          }
      }

      @submissions = pager\get_page @page

      if @params.format == "json"
        return render_submissions_page @, SUBMISSIONS_PER_PAGE, {
          hide_hidden: true
        }

      @title = @user\name_for_display!
      @show_welcome_banner = true
      @has_more = @user.submissions_count > SUBMISSIONS_PER_PAGE

      @following = @user\followed_by @current_user

      with_streak_users = (streaks) ->
        Users\include_in streaks, "user_id"
        StreakUsers\include_in streaks, "streak_id", flip: true, where: {
          user_id: @user.id
        }
        streaks

      @active_streaks = @user\find_participating_streaks({
        publish_status: "published"
        state: "active"
        prepare_results: with_streak_users
      })\get_page!

      @upcoming_streaks = @user\find_participating_streaks({
        publish_status: "published"
        state: "upcoming"
        prepare_results: with_streak_users
      })\get_page!

      @completed_streaks = @user\find_participating_streaks({
        publish_status: "published"
        state: "completed"
        prepare_results: with_streak_users
      })\get_page!

      for streaks in *{@active_streaks, @completed_streaks}
        for streak in *streaks
          continue unless streak.streak_user
          streak.streak_user.streak = streak
          streak.completed_units = streak.streak_user\get_completed_units!

      render: true
  }

  [user_submissions: "/u/:slug/submissions"]: capture_errors {
    on_error: => not_found
    =>
      find_user @
      assert_page @

      show_hidden = @current_user and
        (@current_user\is_admin! or @current_user.id == @user.id)

      import types from require "tableshape"
      shapes = require "helpers.shapes"

      params = assert_error types.shape({
        streak_id: shapes.empty + shapes.db_id
        max_date: shapes.empty + shapes.datestamp
        tag: shapes.empty + types.string\length(1,100) * shapes.trimmed_text
      }, extra_fields: types.any / nil)\transform @params

      pager = @user\find_submissions {
        streak_id: params.streak_id
        max_date: params.max_date
        tag: params.tag

        :show_hidden

        per_page: SUBMISSIONS_PER_PAGE

        prepare_results: (...) ->
          Submissions\preload_for_list ..., {
            likes_for: @current_user
          }
      }

      @submissions = pager\get_page @page
      @has_more = #@submissions == SUBMISSIONS_PER_PAGE

      if @params.format == "json"
        return render_submissions_page @, SUBMISSIONS_PER_PAGE, {
          hide_hidden: not show_hidden
        }

      render: true
  }

  [user_tags: "/u/:slug/tags"]: capture_errors {
    on_error: => not_found
    =>
      find_user @
      @tags_by_frequency = @user\tags_by_frequency!
      render: true
  }

  [user_tag: "/u/:slug/tag/:tag_slug"]: capture_errors {
    on_error: => not_found
    =>
      find_user @
      assert_page @

      pager = @user\find_submissions {
        tag: @params.tag_slug
        show_hidden: @current_user and
          (@current_user\is_admin! or @current_user.id == @user.id)

        per_page: SUBMISSIONS_PER_PAGE
        prepare_results: (...) ->
          Submissions\preload_for_list ..., {
            likes_for: @current_user
          }
      }

      @submissions = pager\get_page @page
      @has_more = #@submissions == SUBMISSIONS_PER_PAGE

      if @params.format == "json"
        return render_submissions_page @, SUBMISSIONS_PER_PAGE, {
          hide_hidden: true
        }

      render: true
  }

  [user_following: "/u/:slug/following"]: capture_errors {
    on_error: => not_found
    =>
      import Followings from require "models"

      find_user @
      assert_page @
      @pager = @user\find_following per_page: 25
      @users = @pager\get_page @page
      Followings\load_for_users @users, @current_user

      @title = "Followed by #{@user\name_for_display!}"
      if @page > 1
        @title ..= " - Page #{@page}"

      render: true
  }

  [user_followers: "/u/:slug/followers"]: capture_errors {
    on_error: => not_found
    =>
      import Followings from require "models"
      find_user @
      assert_page @

      @pager = @user\find_followers per_page: 25
      @users = @pager\get_page @page
      Followings\load_for_users @users, @current_user

      @title = "#{@user\name_for_display!}'s followers"
      if @page > 1
        @title ..= " - Page #{@page}"

      render: true
  }

  [user_streaks_hosted: "/u/:slug/streaks-hosted"]: capture_errors {
    on_error: => not_found
    =>
      find_user @
      assert_page @

      @pager = @user\find_hosted_streaks {
        publish_status: unless @user\allowed_to_edit(@current_user)
          "published"
      }

      @streaks = @pager\get_page @page
      @title = "Streaks hosted by #{@user\name_for_display!}"

      render: true
  }


  [user_register: "/register"]: respond_to {
    before: =>
      if @current_user
        @write redirect_to: @url_for "index"

      @flow("user")\load_return_to!

    GET: => render: true

    POST: capture_errors =>
      assert_csrf @
      trim_filter @params

      assert_valid @params, {
        { "username", exists: true, min_length: 2, max_length: 25 }
        { "password", exists: true, min_length: 2 }
        { "password_repeat", equals: @params.password }
        { "email", exists: true, min_length: 3 }
        { "accept_terms", equals: "yes", "You must accept the Terms of Service" }

        if config.enable_recaptcha
          { "recaptcha_token", exists: "true", "Please allow Google reCAPTCHA to load in order to register (sorry!)" }
      }

      recaptcha_result = if config.enable_recaptcha
        import verify_recaptcha from require "helpers.recaptcha"
        ip = require("helpers.remote_addr")!
        response = verify_recaptcha @params.recaptcha_token, ip
        assert_error response and response.success, "reCAPTCHA response invalid, please try again"
        response

      assert_error @params.email\match(".@."), "invalid email address"

      user = assert_error Users\create {
        username: @params.username
        email: @params.email
        password: @params.password
      }

      user\write_session @

      if recaptcha_result
        import RecaptchaResults from require "models"

        RecaptchaResults\create {
          object_type: "user"
          object_id: user.id
          action: "register"
          data: recaptcha_result
        }

      import RegisterReferrers from require "models"
      if RegisterReferrers\create_from_req user, @
        import unset_register_referrer from require "helpers.referrers"
        unset_register_referrer!

      @session.flash = "Welcome to streak.club!"

      user\refresh_spam_scan!
      redirect_to: @url_for "index"
  }

  [user_login: "/login"]: respond_to {
    before: =>
      if @current_user
        @write redirect_to: @url_for "index"

      @flow("user")\load_return_to!

    GET: => render: true
    POST: capture_errors =>
      assert_csrf @
      assert_valid @params, {
        { "username", exists: true }
        { "password", exists: true }
      }

      user = assert_error Users\login @params.username, @params.password
      user\write_session @

      import unset_register_referrer from require "helpers.referrers"
      unset_register_referrer!

      @session.flash = "Welcome back!"
      redirect_to: @params.return_to or @url_for("index")
  }

  [user_logout: "/logout"]: =>
    @session.user = false
    @session.flash = "You are logged out"
    redirect_to: "/"

  [user_settings: "/user/settings"]: require_login respond_to {
    before: =>
      @user = @current_user
      @user_profile = @user\get_user_profile!

    GET: =>
      render: true

    POST: capture_errors_json =>
      assert_csrf @
      assert_valid @params, {
        {"user", type: "table"}
        {"user_profile", type: "table"}
      }

      user_update = @params.user
      trim_filter user_update, {"display_name"}

      assert_valid user_update, {
        {"display_name", optional: true, max_length: 120}
      }

      user_update.display_name or= db.NULL
      @user\update user_update

      profile_update = @params.user_profile
      trim_filter profile_update, {"website", "twitter", "bio"}, db.NULL

      assert_valid profile_update, {
        {"bio", optional: true, max_length: 1024*1024}
      }

      @user\get_user_profile!\update profile_update

      @session.flash = "Profile updated"

      @user\refresh_spam_scan!
      redirect_to: @url_for "user_settings"
  }

  [user_follow: "/user/:id/follow"]: require_login capture_errors_json =>
    find_user @
    assert_csrf @
    assert_error @current_user.id != @user.id, "invalid user"
    assert_error not @current_user\is_suspended!, "can't follow"

    import Followings, Notifications from require "models"
    following = Followings\create {
      source_user_id: @current_user.id
      dest_user_id: @user.id
    }

    if following
      Notifications\notify_for @user, @current_user, "follow"

    json: { success: not not following }

  [user_unfollow: "/user/:id/unfollow"]: require_login capture_errors_json =>
    find_user @
    assert_csrf @
    assert_error @current_user.id != @user.id, "invalid user"

    import Followings, Notifications from require "models"

    params = {
      source_user_id: @current_user.id
      dest_user_id: @user.id
    }

    success = if f = Followings\find params
      f\delete!
      Notifications\undo_notify @user, @current_user, "follow"
      true

    json: { success: success or false }


  [user_forgot_password: "/user/forgot-password"]: respond_to {
    before: =>
      import UserProfiles from require "models"
      trim_filter @params

      if @params.token and "string" == type @params.token
        id, token = @params.token\match "^(%d+)-(.*)"
        if id
          @profile = UserProfiles\find {
            user_id: id
            password_reset_token: token
          }

      if @profile
        @user = @profile\get_user!

    GET: capture_errors =>
      render: true

    POST: capture_errors =>
      assert_csrf @

      if @profile
        assert_valid @params, {
          { "password", exists: true, min_length: 2 }
          { "password_repeat", equals: @params.password }
        }
        @user\set_password @params.password, @
        @profile\update { password_reset_token: db.NULL }
        @session.flash = "Your password has been updated"
        @user\write_session @
        redirect_to: @url_for"index"
      else
        assert_valid @params, {
          { "email", exists: true, min_length: 3 }
        }

        user = assert_error Users\find({
          [db.raw("lower(email)")]: @params.email\lower!
        }), "don't know anyone with that email"

        token = user\generate_password_reset!

        reset_url = @build_url @url_for "user_forgot_password", nil, { :token }
        mailer = require "emails.password_reset"
        mailer\send @, user.email, { :reset_url, :user }
        @session.flash = "Password reset email has been sent"
        redirect_to: @url_for "index"
  }

