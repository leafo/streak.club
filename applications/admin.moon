
lapis = require "lapis"
db = require "lapis.db"

config = require("lapis.config").get!

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

  [admin_feature_submission: "/feature-submission/:id"]: respond_to {
    POST: capture_errors_json =>
      assert_csrf @
      import Submissions, FeaturedSubmissions from require "models"

      submission = assert_error Submissions\find(@params.id), "invalid submission"

      assert_valid @params, {
        {"action", one_of: {"create", "delete"}}
      }

      res = switch @params.action
        when "create"
          FeaturedSubmissions\create submission_id: submission.id
        when "delete"
          FeaturedSubmissions\load(submission_id: submission.id)\delete!

      json: { success: true, :res }

  }


  [admin_featured_streak: "/feature-streak/:id"]: respond_to {
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

  [admin_streak: "/streak/:id"]: capture_errors_json respond_to {
    before: =>
      import Streaks from require "models"
      @streak = assert_error Streaks\find(@params.id), "invalid streak"

    GET: =>
      render: true
  }


  [admin_submission: "/submission/:id"]: capture_errors_json respond_to {
    before: =>
      import Submissions from require "models"
      @submission = assert_error Submissions\find(@params.id), "invalid submission"

    GET: =>
      render: true

    POST: =>
      assert_csrf @
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
        {"action", one_of: {"dry_run", "preview", "send"}}
      }

      email = trim_filter @params.email

      assert_valid email, {
        {"subject", exists: true}
        {"body", exists: true}
      }

      users = Users\select "
        where id in
          (select user_id from streak_users where streak_id = ? and submissions_count = 0)
      ", @streak.id, fields: "id, username, email, display_name"

      if @params.action == "dry_run"
        return json: {
          emails: [u.email for u in *users]
        }

      recipeints = if @params.action == "preview"
        { { config.admin_email, {name_for_display: "Test user"}} }
      else
        [{u.email, {name_for_display: u\name_for_display!}} for u in *users]

      template = require "emails.reminder_email"
      t = template {
        email_body: email.body
        email_subject: email.subject
        show_tag_unsubscribe: true
      }
      t\include_helper @

      vars = {}
      emails = for {email, email_vars} in *recipeints
        vars[email] = email_vars
        email

      import send_email from require "helpers.email"
      res = send_email emails, t\subject!, t\render_to_string!, {
        html: true
        sender: "Streak Club <postmaster@streak.club>"
        tags: { "reminder_email" }
        :vars
        track_opens: true
        headers: {
          "Reply-To": config.admin_email
        }
      }

      json: { success: true, :res }

  }

