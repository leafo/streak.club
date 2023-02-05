
lapis = require "lapis"
db = require "lapis.db"

import preload from require "lapis.db.model"

config = require("lapis.config").get!

types = require "lapis.validate.types"
shapes = require "helpers.shapes"

import respond_to, capture_errors_json, assert_error from require "lapis.application"
import assert_valid, with_params from require "lapis.validate"

import not_found, assert_page, with_csrf from require "helpers.app"

import ExceptionRequests, ExceptionTypes from require "lapis.exceptions.models"

-- this converts params object to a WHERE clause string of optional filters
filter_shape = (t) ->
  spec = {}
  for k,v in pairs t
    table.insert spec, {k, types.empty + v}

  table.sort spec, (a,b) -> a[1] < b[1]
  types.params_shape(spec) / (filters) ->
    if next filters
      (db.interpolate_query "WHERE ?", db.clause [v for _,v in pairs filters])
    else
      "" -- no filter

class AdminApplication extends lapis.Application
  @name: "admin."
  @path: "/admin"

  @before_filter =>
    unless @current_user and @current_user\is_admin!
      @write not_found

  [home: ""]: =>
    render: true

  [feature_submission: "/feature-submission/:id"]: respond_to {
    POST: capture_errors_json with_csrf with_params {
      {"id", types.db_id}
      {"action", types.one_of {"create", "delete"}}
    }, (params) =>
      import Submissions, FeaturedSubmissions from require "models"

      submission = assert_error Submissions\find(params.id), "invalid submission"

      res = switch params.action
        when "create"
          FeaturedSubmissions\create submission_id: submission.id
        when "delete"
          FeaturedSubmissions\load(submission_id: submission.id)\delete!

      json: { success: true, :res }
  }


  [featured_streak: "/feature-streak/:id"]: respond_to {
    POST: capture_errors_json with_csrf with_params {
      {"id", types.db_id}
      {"action", types.one_of {"create", "delete"}}
    }, (params) =>
      import Streaks, FeaturedStreaks from require "models"

      streak = assert_error Streaks\find(params.id), "invalid streak"

      res = switch params.action
        when "create"
          FeaturedStreaks\create streak_id: streak.id
        when "delete"
          FeaturedStreaks\load(streak_id: streak.id)\delete!

      json: { success: true, :res }
  }

  [streaks: "/streaks"]: capture_errors_json with_params {
    {"page", shapes.page_number}
  }, (params) =>
    import Streaks, Users from require "models"

    @pager = Streaks\paginated "order by id desc", {
      per_page: 50
      prepare_results: (streaks) ->
        preload streaks, "user"
        streaks
    }

    @page = params.page
    @streaks = @pager\get_page @page
    render: true


  [streak: "/streak/:id"]: capture_errors_json respond_to {
    before: with_params {
      {"id", types.db_id}
    }, (params) =>
      import Streaks, RelatedStreaks from require "models"
      @streak = assert_error Streaks\find(params.id), "invalid streak"

      @related = @streak\get_related_streaks!
      @other_related = @streak\get_other_related_streaks!

      all_related = {unpack @related}
      for s in *@other_related
        table.insert all_related, s

      preload all_related, "streak", "other_streak"

    GET: =>
      render: true

    POST: with_csrf with_params {
      {"action", types.one_of {"add_related", "remove_related"}}
    }, (params) =>
      import Streaks, RelatedStreaks from require "models"

      switch params.action
        when "remove_related"
          {:related_streak_id} = assert_valid @params, types.params_shape {
            {"related_streak_id", types.db_id}
          }

          rs = RelatedStreaks\find related_streak_id
          if rs
            rs\delete!
            @session.flash = "related streak deleted"

        when "add_related"
          new_related = assert_valid @params.related, types.params_shape {
            {"type", types.db_enum RelatedStreaks.types}
            {"streak_id", types.db_id}
            {"reason", types.empty + types.limited_text 256}
          }

          other_streak = Streaks\find new_related.streak_id
          assert_error other_streak, "invalid other streak"

          RelatedStreaks\create {
            streak_id: @streak.id
            type: new_related.type
            other_streak_id: other_streak.id
            reason: new_related.reason
          }

          @session.flash = "related streak added"

      redirect_to: @admin_url_for @streak
  }


  [submission: "/submission/:id"]: capture_errors_json respond_to {
    before: with_params {
      {"id", types.db_id}
    }, (params) =>
      import Submissions from require "models"
      @submission = assert_error Submissions\find(params.id), "invalid submission"

    GET: =>
      import Uploads from require "models"
      @uploads = Uploads\select "
        where object_type = ? and object_id = ?
        order by position
      ", Uploads.object_types.submission, @submission.id

      render: true

    POST: with_csrf with_params {
      {"action", types.one_of {"remove_submission", "update_submission"}}
    }, (params) =>
      import StreakSubmissions from require "models"

      switch params.action
        when "remove_submission"
          {:streak_id} = assert_valid @params, types.params_shape {
            {"confirm", -types.empty}
            {"streak_id", types.db_id}
          }

          submit = StreakSubmissions\find {
            submission_id: @submission.id
            streak_id: streak_id
          }

          submit\delete!
          @session.flash = "Submission removed from streak"
        when "update_submission"
          {:streak_id, submit: submit_update} = assert_valid @params, types.params_shape {
            {"streak_id", types.db_id}
            {"submit", types.params_shape {
              {"submit_time", shapes.timestamp}
              {"late_submit", types.empty / false + types.any / true}
            }}
          }

          submit = StreakSubmissions\find {
            submission_id: @submission.id
            streak_id: streak_id
          }

          submit\update submit_update
          @session.flash = "Submission updated"

      redirect_to: @admin_url_for @submission
  }

  [users: "/users"]: capture_errors_json respond_to {
    POST: with_csrf with_params {
      {"action", types.one_of {"bulk_train_spam"}}
      {"confirm", -types.empty}
    }, (params) =>
      import Users, SpamScans from require "models"

      get_users = ->
        {:user_ids} = assert_valid @params, types.params_shape {
          {"user_ids", types.map_of(types.db_id, "on") / (t) ->
            [k for k in pairs t]
          }
        }

        Users\select "where id in ?", db.list user_ids

      updated = 0

      switch params.action
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

    GET: with_params {
      {"page", shapes.page_number}
    }, (params) =>
      import Users from require "models"

      filter = assert_valid @params, filter_shape {
        id: types.db_id / (id) -> db.clause { :id }
        user_token: types.trimmed_text / (v) ->
          db.clause {
            {"exists(select 1 from spam_scans where user_id = users.id and user_tokens @> ARRAY[?])", v}
          }
        exclude_token: types.trimmed_text / (v) ->
          db.clause {
            {"not exists(select 1 from spam_scans where user_id = users.id and user_tokens @> ARRAY[?])", v}
          }
        spam_untrained: types.any / ->
          import SpamScans from require "models"
          db.clause {
            {"exists(select 1 from spam_scans where user_id = users.id and train_status = ?) or not exists(select 1 from spam_scans where user_id = users.id)", SpamScans.train_statuses.untrained}
          }
      }

      @pager = Users\paginated "#{filter} order by id desc", {
        per_page: 50
        prepare_results: (users) ->
          preload users, "ip_addresses", "spam_scan"
          users
      }

      @page = params.page
      @users = @pager\get_page @page

      render: true
  }

  [user: "/user/:id"]: capture_errors_json respond_to {
    before: with_params {
      {"id", types.db_id}
    }, (params) =>
      import Users from require "models"
      @user = assert_error Users\find(params.id), "invalid user"

    GET: =>
      render: true

    POST: with_csrf with_params {
      {"action", types.one_of { "set_password", "update_flags" }}
    }, =>
      switch @params.action
        when "set_password"
          {:password} = assert_valid @params, types.params_shape {
            {"password", types.valid_text}
          }
          @user\set_password password
          @session.flash = "Password updated"

        when "update_flags"
          update = assert_valid @params, types.params_shape {
            {"spam", types.empty / false + types.literal("on") / true}
            {"suspended", types.empty / false + types.literal("on") / true}
          }

          if @user\update_flags update
            @session.flash = "updated flags to: #{@user.flags}"

      redirect_to: @admin_url_for @user
  }

  [send_streak_email: "/email/:streak_id/email"]: capture_errors_json respond_to {
    before: with_params {
      {"streak_id", types.db_id}
      {"email", types.one_of {"deadline", "late_submit"}}
    }, (params)=>
      import Streaks from require "models"
      @streak = assert_error Streaks\find(params.streak_id), "invalid streak"
      @email_type = params.email

    GET: =>
      emails = switch @email_type
        when "deadline"
          [su\get_user!.email for su in *@streak\find_unsubmitted_users!]
        when "late_submit"
          prev_unit = @streak\increment_date_by_unit @streak\current_unit!, -1
          streak_users = @streak\find_unsubmitted_users prev_unit
          [su\get_user!.email for su in *streak_users]
        else
          error "unknown email type"

      json: {
        count: #emails
        emails: emails
      }

    POST: with_csrf =>
      res = switch @email_type
        when "deadline"
          { @streak\send_deadline_email @ }
        when "late_submit"
          { @streak\send_late_submit_email @ }

      json: res

  }

  [email_streak: "/email/:streak_id"]: capture_errors_json respond_to {
    before: with_params {
      {"streak_id", types.db_id}
    }, (params) =>
      import Streaks from require "models"
      @streak = assert_error Streaks\find(params.streak_id), "invalid streak"

    GET: => render: true

    POST: with_csrf with_params {
      {"email", types.params_shape {
        {"subject", types.trimmed_text}
        {"body", types.trimmed_text}
      }}
      {"action", types.one_of { "dry_run", "preview", "send" }}
    }, (params) =>
      import Users from require "models"

      users = Users\select "
        where id in
          (select user_id from streak_users where streak_id = ?)
      ", @streak.id, fields: "id, username, email, display_name"

      if params.action == "dry_run"
        return json: {
          emails: [u.email for u in *users]
        }

      recipeints = if params.action == "preview"
        { { config.admin_email, {name_for_display: "Test user"}} }
      else
        [{u.email, {name_for_display: u\name_for_display!}} for u in *users]

      template = require "emails.generic_email"
      t = template {
        email_body: params.email.body
        email_subject: params.email.subject
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

  [comments: "/comments"]: capture_errors_json with_params {
    {"page", shapes.page_number}
  }, (params) =>
    import SubmissionComments from require "models"

    @pager = SubmissionComments\paginated "order by id desc", {
      per_page: 50
      prepare_results: (comments) ->
        preload comments, "user", submission: { "user", streak_submissions: "streak"}
        comments
    }

    @page = params.page
    @comments = @pager\get_page @page
    render: true

  [community_posts: "/community-posts"]: capture_errors_json with_params {
    {"page", shapes.page_number}
  }, (params) =>
    import Posts from require "community.models"

    @pager = Posts\paginated "order by id desc", {
      per_page: 50
      prepare_results: (posts) ->
        preload posts, "user", topic: { category: "streak" }
        posts
    }

    @page = params.page
    @posts = @pager\get_page @page
    render: true

  [uploads: "/uploads"]: capture_errors_json with_params {
    {"page", shapes.page_number}
  }, (params) =>
    import Uploads from require "models"

    filter = assert_valid @params, filter_shape {
      id: types.db_id / (id) -> db.clause { :id }
      ready: types.any / db.clause { ready: true }
      deleted: types.any / db.clause { deleted: true }
      extension: types.trimmed_text / (ext) -> db.clause { extension: ext }
      user_id: types.db_id / (id) -> db.clause { user_id: id }
      storage_type: types.db_enum(Uploads.storage_types) / (v) -> db.clause { storage_type: v }
      submission_id: types.db_id / (id) ->
        db.clause {
          object_id: id
          object_type: Uploads.object_types.submission
        }
    }

    @pager = Uploads\paginated "#{filter} order by id desc", {
      per_page: 50
      prepare_results: (uploads) ->
        preload uploads, "user", "object"
        uploads
    }

    @page = params.page
    @uploads = @pager\get_page @page
    render: true

  [spam_queue: "/spam-queue"]: capture_errors_json respond_to {
    before: with_params {
      {"user_id", types.empty + types.db_id}
    }, (params) =>
      import Users from require "models"
      if params.user_id
        @user = assert_error Users\find(params.user_id), "invalid user id"

    GET: =>
      -- get the next user
      import Users, SpamScans from require "models"

      unless @user
        top = unpack SpamScans\select "
          inner join users on users.id = spam_scans.user_id
          where train_status not in ? and review_status != ?
          and exists(select 1 from users where users.id = spam_scans.user_id and (submissions_count > 0 or streaks_count > 0))
          order by score * sqrt(1.0 + users.streaks_count + users.submissions_count) desc nulls last limit 1
        ", db.list({ SpamScans.train_statuses.ham, SpamScans.train_statuses.spam }), SpamScans.review_statuses.reviewed, {
            fields: "spam_scans.*"
          }

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

    POST: with_csrf with_params {
      {"action", types.one_of {
        "refresh"
        "train"

        "dismiss"
        "dismiss_as_spam"
      }}

    }, (params) =>
      local scan

      switch params.action
        when "dismiss", "dismiss_as_spam"
          scan = assert_error @user\get_spam_scan!, "user has no spam scan"
          assert_error scan\mark_reviewed!, "failed to mark reviewed"

          @session.flash = "marked spam as reviewed"

          if params.action == "dismiss_as_spam"
            @session.flash ..= "and suspended account"
            @user\update_flags {
              spam: true
              suspended: true
            }
        when "train"
          import SpamScans from require "models"
          scan = SpamScans\refresh_for_user @user
          assert_error scan, "scan not available for train"

          {train: train_as} = assert_valid @params, types.params_shape {
            {"train", types.one_of {"ham", "spam"}}
          }

          assert_error scan\train train_as

          @session.flash = "Trained #{train_as}"

          if train_as == "spam"
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

  [exceptions: "/exceptions"]: capture_errors_json respond_to {
    GET: with_params {
      {"page", shapes.page_number}
    }, (params) =>
      filter = assert_valid @params, filter_shape {
        id: types.db_id / (id) -> db.clause { :id }
        exception_type_id: types.db_id / (id) -> db.clause { exception_type_id: id }
        status: types.db_enum(ExceptionTypes.statuses) / (v) ->
          db.clause {
            {"exists(select 1 from exception_types where exception_types.id = exception_requests.exception_type_id and status = ?)", v}
          }
      }

      @pager = ExceptionRequests\paginated "#{filter} order by id desc", {
        per_page: 50
        prepare_results: (exceptions) ->
          preload exceptions, "exception_type"
          exceptions
      }

      @page = params.page
      @exceptions = @pager\get_page @page
      render: true

    POST: with_csrf with_params {
      {"action", types.one_of {"set_exception_status"}}
    }, (params) =>
      switch params.action
        when "set_exception_status"
          {:exception_request_id, status: set_status} = assert_valid @params, types.params_shape {
            {"exception_request_id", types.db_id}
            {"status", types.db_enum ExceptionTypes.statuses}
          }

          er = ExceptionRequests\find exception_request_id
          assert_error er, "invalid exception request"
          et = assert_error er\get_exception_type!, "exception request does not have exception type"

          et\update {
            status: set_status
          }

          return redirect_to: @url_for "admin.exceptions", nil, exception_type_id: et.id

  }


