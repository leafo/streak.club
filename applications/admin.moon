
lapis = require "lapis"
db = require "lapis.db"

import preload from require "lapis.db.model"

config = require("lapis.config").get!

import respond_to, capture_errors_json, assert_error from require "lapis.application"
import assert_valid from require "lapis.validate"
import trim_filter from require "lapis.util"

import not_found, assert_page from require "helpers.app"
import assert_csrf from require "helpers.csrf"

class AdminApplication extends lapis.Application
  @name: "admin."
  @path: "/admin"

  @before_filter =>
    unless @current_user and @current_user\is_admin!
      @write not_found

  [home: ""]: =>
    render: true

  [feature_submission: "/feature-submission/:id"]: respond_to {
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


  [featured_streak: "/feature-streak/:id"]: respond_to {
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

  [streaks: "/streaks"]: capture_errors_json =>
    import Streaks, Users from require "models"

    @pager = Streaks\paginated "order by id desc", {
      per_page: 50
      prepare_results: (streaks) ->
        Users\include_in streaks, "user_id"
        streaks
    }

    assert_page @
    @streaks = @pager\get_page @page
    render: true


  [streak: "/streak/:id"]: capture_errors_json respond_to {
    before: =>
      import Streaks, RelatedStreaks from require "models"
      @streak = assert_error Streaks\find(@params.id), "invalid streak"

      @related = @streak\get_related_streaks!
      @other_related = @streak\get_other_related_streaks!

      all_related = {unpack @related}
      for s in *@other_related
        table.insert all_related, s

      preload all_related, "streak", "other_streak"

    GET: =>
      render: true

    POST: =>
      assert_csrf @
      assert_valid @params, {
        {"related", optional: true, type: "table"}
        {"action", one_of: {"add_related", "remove_related"}}
      }

      import Streaks, RelatedStreaks from require "models"

      switch @params.action
        when "remove_related"
          assert_valid @params, {
            {"related_streak_id", is_integer: true}
          }

          rs = RelatedStreaks\find @params.related_streak_id
          if rs
            rs\delete!
            @session.flash = "related streak deleted"

        when "add_related"
          assert_valid @params.related, {
            {"type", one_of: {unpack RelatedStreaks.types}}
            {"streak_id", is_integer: true}
            {"reason", type: "string", optional: true}
          }

          other_streak = Streaks\find @params.related.streak_id
          assert_error other_streak, "invalid other streak"

          RelatedStreaks\create {
            streak_id: @streak.id
            type: @params.related.type
            other_streak_id: other_streak.id
            reason: @params.related.reason
          }

          @session.flash = "related streak added"

      redirect_to: @admin_url_for @streak
  }


  [submission: "/submission/:id"]: capture_errors_json respond_to {
    before: =>
      import Submissions from require "models"
      @submission = assert_error Submissions\find(@params.id), "invalid submission"

    GET: =>
      import Uploads from require "models"
      @uploads = Uploads\select "
        where object_type = ? and object_id = ?
        order by position
      ", Uploads.object_types.submission, @submission.id

      render: true

    POST: =>
      assert_csrf @
      assert_valid @params, {
        {"action", one_of: {"remove_submission", "update_submission"}}
      }

      import StreakSubmissions from require "models"

      switch @params.action
        when "remove_submission"
          assert_error @params.confirm == "true", "Please tick confirm"

          submit = StreakSubmissions\find {
            submission_id: @submission.id
            streak_id: @params.streak_id
          }

          submit\delete!
          @session.flash = "Submission removed from streak"
        when "update_submission"
          submit = StreakSubmissions\find {
            submission_id: @submission.id
            streak_id: @params.streak_id
          }

          assert_valid @params, {
            {"submit", type: "table"}
          }

          submit_update = trim_filter @params.submit
          submit\update {
            submit_time: submit_update.submit_time
            late_submit: not not submit_update.late_submit
          }
          @session.flash = "Submission updated"

      redirect_to: @admin_url_for @submission
  }

  [users: "/users"]: capture_errors_json respond_to {
    POST: =>
      assert_csrf @

      assert_valid @params, {
        {"action", one_of: {"bulk_train_spam"}}
      }

      import Users, SpamScans from require "models"

      get_users = ->
        user_ids = [k for k,v in pairs(@params.user_ids) when v == "on"]
        Users\select "where id in ?", db.list user_ids

      updated = 0

      switch @params.action
        when "bulk_train_spam"
          users = get_users!
          preload users, "spam_scan"
          for user in *users
            scan = user.spam_scan or SpamScans\refresh_for_user user
            if scan and scan\train "spam"
              user\update_flags {
                spam: true
                suspended: true
              }

              updated += 1

      json: { success: true, :updated }

    GET: =>
      import Users from require "models"

      wheres = {}

      add_where = (q) ->
        table.insert wheres, "(#{q})"

      if @params.user_token
        add_where db.interpolate_query "exists(select 1 from spam_scans where user_id = users.id and user_tokens @> ARRAY[?])", @params.user_token

      if @params.spam_untrained
        import SpamScans from require "models"
        add_where db.interpolate_query "exists(select 1 from spam_scans where user_id = users.id and train_status = ?) or not exists(select 1 from spam_scans where user_id = users.id)", SpamScans.train_statuses.untrained


      clause = "order by id desc"

      if next wheres
        clause = "where #{table.concat wheres, " and "} #{clause}"

      @pager = Users\paginated clause, {
        per_page: 50
        prepare_results: (users) ->
          preload users, "ip_addresses", "spam_scan"
          users
      }

      assert_page @
      @users = @pager\get_page @page

      render: true
  }

  [user: "/user/:id"]: capture_errors_json respond_to {
    before: =>
      import Users from require "models"
      @user = assert_error Users\find(@params.id), "invalid user"

    GET: =>
      render: true

    POST: =>
      assert_csrf @

      assert_valid @params, {
        {"action", one_of: {
          "set_password"
          "update_flags"
        }}
      }

      switch @params.action
        when "set_password"
          assert_valid @params, {
            {"password", exists: true}
          }
          @user\set_password @params.password
          @session.flash = "Password updated"

        when "update_flags"
          update = { flag_name, @params[flag_name] == "on" for flag_name in *{"spam", "suspended"} }

          if @user\update_flags update
            @session.flash = "updated flags to: #{@user.flags}"

      redirect_to: @admin_url_for @user
  }

  [send_streak_email: "/email/:streak_id/email"]: capture_errors_json respond_to {
    before: =>
      import Streaks from require "models"
      assert_error @params, {
        {"streak_id", is_integer: true}
        {"email", one_of: {"deadline", "late_submit"}}
      }

      @streak = assert_error Streaks\find(@params.streak_id), "invalid streak"

    GET: =>
      emails = switch @params.email
        when "deadline"
          [su\get_user!.email for su in *@streak\find_unsubmitted_users!]
        when "late_submit"
          prev_unit = @streak\increment_date_by_unit @streak\current_unit!, -1
          streak_users = @streak\find_unsubmitted_users prev_unit
          [su\get_user!.email for su in *streak_users]

      json: {
        count: #emails
        emails: emails
      }

    POST: =>
      assert_csrf @
      res = switch @params.email
        when "deadline"
          { @streak\send_deadline_email @ }
        when "late_submit"
          { @streak\send_late_submit_email @ }

      json: res

  }

  [email_streak: "/email/:streak_id"]: capture_errors_json respond_to {
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
          (select user_id from streak_users where streak_id = ?)
      ", @streak.id, fields: "id, username, email, display_name"

      if @params.action == "dry_run"
        return json: {
          emails: [u.email for u in *users]
        }

      recipeints = if @params.action == "preview"
        { { config.admin_email, {name_for_display: "Test user"}} }
      else
        [{u.email, {name_for_display: u\name_for_display!}} for u in *users]

      template = require "emails.generic_email"
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

  [comments: "/comments"]: =>
    import SubmissionComments from require "models"

    @pager = SubmissionComments\paginated "order by id desc", {
      per_page: 50
      prepare_results: (comments) ->
        preload comments, "user", submission: { "user", streak_submissions: "streak"}
        comments
    }

    assert_page @
    @comments = @pager\get_page @page
    render: true

  [community_posts: "/community-posts"]: =>
    import Posts from require "community.models"

    @pager = Posts\paginated "order by id desc", {
      per_page: 50
      prepare_results: (posts) ->
        preload posts, "user", topic: { category: "streak" }
        posts
    }

    assert_page @
    @posts = @pager\get_page @page
    render: true

  [uploads: "/uploads"]: =>
    import Uploads from require "models"

    @pager = Uploads\paginated "order by id desc", {
      per_page: 50
      prepare_results: (uploads) ->
        preload uploads, "user", "object"
        uploads
    }

    assert_page @
    @uploads = @pager\get_page @page
    render: true

  [spam_queue: "/spam-queue"]: capture_errors_json respond_to {
    before: =>
      import Users from require "models"
      if @params.user_id
        @user = assert_error Users\find(@params.user_id), "invalid user id"

    GET: =>
      -- get the next user
      import Users, SpamScans from require "models"

      unless @user
        top = unpack SpamScans\select "where train_status not in ? and review_status != ? order by score desc nulls last limit 1",
          db.list({ SpamScans.train_statuses.ham, SpamScans.train_statuses.spam }), SpamScans.review_statuses.reviewed

        user = top and top\get_user!

        unless user
          user = unpack Users\select "
            where not exists(select 1 from spam_scans where user_id = users.id)
            and (
              exists(select 1 from user_profiles where user_profiles.user_id = users.id and (bio is not null or website is not null))
              or
              exists(select 1 from streaks where streaks.user_id = users.id)
            )
            order by submissions_count desc, streaks_count desc, id desc
            limit 1
          "

        assert_error user, "no next user on queue"

        if @flash
          @session.flash = @flash -- forward the flash from previous action

        return redirect_to: @url_for "admin.spam_queue", nil, user_id: user.id

      import SpamScans from require "models"

      if tokens = SpamScans\tokenize_user @user
        @user_token_score = SpamScans\score_user_tokens tokens
        @user_token_summary = SpamScans\summarize_tokens tokens, {
          "user_spam"
          "user_ham"
        }

      if tokens = SpamScans\tokenize_user_text @user
        @text_token_score = SpamScans\score_text_tokens tokens
        @text_token_summary = SpamScans\summarize_tokens tokens, {
          "text_spam"
          "text_ham"
        }

      render: true

    POST: =>
      assert_csrf @

      assert_valid @params, {
        {"action", one_of: {
          "refresh"
          "train"

          "dismiss"
          "dismiss_as_spam"
        }}
      }

      local scan

      switch @params.action
        when "dismiss", "dismiss_as_spam"
          scan = assert_error @user\get_spam_scan!, "user has no spam scan"
          assert_error scan\mark_reviewed!, "failed to mark reviewed"

          @session.flash = "marked spam as reviewed"

          if @params.action == "dismiss_as_spam"
            @session.flash ..= "and suspended account"
            @user\update_flags {
              spam: true
              suspended: true
            }
        when "train"
          import SpamScans from require "models"
          scan = SpamScans\refresh_for_user @user
          assert_error scan, "scan not available for train"

          assert_valid @params, {
            {"train", one_of: {
              "ham"
              "spam"
            }}
          }

          assert_error scan\train @params.train

          @session.flash = "Trained #{@params.train}"

          if @params.train == "spam"
            @user\update_flags {
              spam: true
              suspended: true
            }

            @session.flash ..= " and suspended"

        when "refresh"
          import SpamScans from require "models"
          scan = SpamScans\refresh_for_user @user
          if scan
            @session.flash = "refreshed spam scan: score: #{scan.score}"
            return redirect_to: @admin_url_for scan

      if scan and not scan\is_reviewed! and not scan\is_trained!
        return redirect_to: @admin_url_for scan

      redirect_to: @url_for "admin.spam_queue"
  }



