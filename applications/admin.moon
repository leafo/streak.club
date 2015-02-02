
lapis = require "lapis"
db = require "lapis.db"

import respond_to, capture_errors_json, assert_error from require "lapis.application"
import assert_valid from require "lapis.validate"
import trim_filter from require "lapis.util"

import not_found from require "helpers.app"
import assert_csrf from require "helpers.csrf"

class AdminApplication extends lapis.Application
  @path: "/admin"

  @before_filter =>
    unless @current_user and @current_user\is_admin!
      @write not_found

  [admin_featured_streak: "/feature/:id"]: respond_to {
    POST: capture_errors_json =>
      assert_csrf @

      import Streaks, FeaturedStreaks from require "models"

      streak = assert_error Streaks\find(@params.id), "invalid streak"

      assert_valid @params, {
        {"action", one_of: {"create", "delete"}}
      }

      res = switch @params.action
        when "create"
          FeaturedStreaks\create streak_id: streak.id
        when "delete"
          FeaturedStreaks\load(streak_id: streak.id)\delete!

      json: { success: true, :res }
  }

  [admin_user: "/user/:id"]: capture_errors_json respond_to {
    before: =>
      import Users from require "models"
      @user = assert_error Users\find(@params.id), "invalid user"

    GET: =>
      render: true

    POST: =>
      assert_csrf @

      assert_valid @params, {
        {"action", one_of: {"set_password"}}
      }

      switch @params.action
        when "set_password"
          assert_valid @params, {
            {"password", exists: true}
          }
          @user\set_password @params.password
          @session.flash = "Password updated"

      redirect_to: @url_for "admin_user", id: @user.id
  }

  [admin_email_streak: "/email/:streak_id"]: capture_errors_json respond_to {
    before: =>
      import Streaks from require "models"
      assert_error @params, {
        {"streak_id", is_integer: true}
      }
      @streak = assert_error Streaks\find(@params.streak_id), "invalid streak"

    GET: => render: true

    POST: =>
      assert_csrf @

      import Users from require "models"
      assert_valid @params, {
        {"email", type: "table"}
      }

      email = trim_filter @params.email

      assert_valid email, {
        {"action", one_of: {"dry_run", "preview", "send"}}
      }

      users = Users\select "
        where id in
          (select user_id from streak_users where streak_id = ? and submissions_count = 0)
      ", @streak.id, fields: "id, username, email"

      -- get all users that have not submitted
      json: { success: true, params: @params, :users }

  }

