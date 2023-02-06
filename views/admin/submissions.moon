
import Submissions from require "models"

import enum from require "lapis.db.model"

class AdminSubmissions extends require "widgets.admin.page"
  @include "widgets.pagination_helpers"
  @include "widgets.table_helpers"

  @needs: {"submissions", "pager"}

  page_name: "submissions"

  column_content: =>
    h2 "Submissions"

    @filter_form (field) ->
      field "id"
      field "user_id"
      fieldset ->
        legend "Visibility"

        field "published", type: "boolean"
        field "hidden", type: "boolean"
        field "deleted", type: "boolean"

    @render_pager @pager

    @column_table @streaks, {
      {"", (submission) ->
        a href: @admin_url_for(submission), "Admin"
      }
      {"", (submission) ->
        a href: @url_for(submission), "View"
      }
      "id"
      "title"
      {"user", (submission) ->
        user = submission\get_user!
        a href: @url_for(user), user\name_for_display!
        if user\is_suspended!
          strong " suspended"

        if user\is_spam!
          strong " spam"
      }
      "published"
      "deleted"
      {"likes_count", label: "likes"}
      {"comments_count", label: "comments"}
      "hidden"
      {"streaks", (submission) ->
        submits = submission\get_streak_submissions!
        for idx, submit in ipairs submits
          if idx > 1
            text ", "

          streak = submit\get_streak!
          a href: @url_for(streak), streak.title

      }
      {"uploads", (submission) ->
        for idx, upload in ipairs submission\get_uploads!
          if idx > 1
            text ", "

          span class: "upload", ->
            a href: @url_for("admin.uploads", nil, id: upload.id), ->
              text upload.filename or -> em "Upload #{upload.id}"
            if upload.size
              text " (#{@filesize_format upload.size})"
      }
      "created_at"
      "updated_at"
    }

    @render_pager @pager
