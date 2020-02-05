
import SubmissionComments from require "models"

class AdminComments extends require "widgets.admin.page"
  @needs: {"comments"}
  @include "widgets.table_helpers"
  @include "widgets.pagination_helpers"

  column_content: =>
    h2 "Submission comments"
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
      }
      {"source", SubmissionComments.sources}
      ":extract_text"
    }

    @render_pager @pager

