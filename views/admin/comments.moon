
import SubmissionComments from require "models"

class AdminComments extends require "widgets.admin.page"
  @needs: {"comments"}
  @include "widgets.table_helpers"
  @include "widgets.pagination_helpers"

  page_name: "comments"

  column_content: =>
    h2 "Submission comments"

    @filter_form (field) ->
      field "user_id"
      field "submission_id"
      field "source", SubmissionComments.sources

    @render_pager @pager
    @column_table @comments, {
      {"created_at", (c) ->
        span title: c.created_at, @relative_timestamp c.created_at
      }

      {"submission", (c) ->
        submission = c\get_submission!
        user = submission\get_user!
        a href: @url_for(submission), submission.title or "untitled"
        text " by "
        a href: @url_for(user), user\name_for_display!
      }
      {"user", (c) ->
        if user = c\get_user!
          a href: @url_for(user), user\name_for_display!

          if user\is_suspended!
            strong " suspended"

          if user\is_spam!
            strong " spam"
      }
      {"source", SubmissionComments.sources}
      "deleted"
      ":extract_text"
    }

    @render_pager @pager

