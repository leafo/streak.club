
lapis = require "lapis"

import with_params from require "lapis.validate"

types = require "lapis.validate.types"

import
  respond_to
  capture_errors
  assert_error
  capture_errors_json
  yield_error
  from require "lapis.application"

import not_found, require_login, assert_unit_date, assert_page, with_csrf from require "helpers.app"
import assert_signed_url from require "helpers.url"

import Submissions, SubmissionComments from require "models"

COMMENTS_PER_PAGE = 25

find_submission = with_params {
  {"id", types.db_id}
}, (params) =>
  @submission = Submissions\find params.id
  assert_error @submission, "invalid submission"

find_comment = with_params {
  {"id", types.db_id}
}, (params) =>
  @comment = SubmissionComments\find params.id
  assert_error @comment, "invalid comment"

view_submission = capture_errors {
  on_error: =>
    not_found

  =>
    find_submission @
    if @params.slug != @submission\slug!
      return redirect_to: @url_for @submission

    @canonical_url = @build_url @url_for(@submission)

    @user = @submission\get_user!
    Submissions\preload_for_list { @submission }, {
      likes_for: @current_user
    }

    @submission.comments = @submission\find_comments(per_page: COMMENTS_PER_PAGE)\get_page!
    @submission.has_more_comments = @submission.comments_count > #@submission.comments

    @streak_submissions = @submission.streak_submissions -- from preload for list

    streaks = [s.streak for s in *@streak_submissions]

    import Users, StreakUsers from require "models"
    Users\include_in streaks, "user_id"
    StreakUsers\include_in streaks, "streak_id", flip: true, where: {
      user_id: @user.id
    }

    for streak in *streaks
      -- doesn't exist if they joined, submitted, then left
      if streak.streak_user
        streak.streak_user.streak = streak
        streak.completed_units = streak.streak_user\get_completed_units!

    @show_welcome_banner = true
    @title = @submission\meta_title!

    -- load their other submissions from the streak
    if #@streak_submissions == 1
      import StreakSubmissions from require "models"
      other_submissions = StreakSubmissions\paginated "
        where user_id = ? and streak_id = ? and submission_id not in (?)
        order by submit_time desc
      ", @submission.user_id, @streak_submissions[1].streak_id, @submission.id, {
        per_page: 20
        prepare_results: (streak_submissions) ->
          Submissions\include_in streak_submissions, "submission_id"
          submissions = [s.submission for s in *streak_submissions when s.submission]
          Submissions\preload_for_list submissions, {
            likes_for: @current_user
          }
      }

      @other_submissions = other_submissions\get_page!


    -- if there's an image in it, make it the page's image
    if image = unpack @submission\get_images!
      @meta_image = image\image_url!

    render: "view_submission"
}


class SubmissionsApplication extends lapis.Application
  "/p/:id": => redirect_to: @url_for "view_submission", id: @params.id
  [view_submission_slug: "/p/:id/:slug"]: view_submission
  [view_submission: "/submission/:id"]: view_submission

  [new_submission: "/submit"]: require_login capture_errors {
    on_error: => not_found

    respond_to {
      before: =>
        if @params.date
          assert_signed_url @
          import Streaks from require "models"

          @streak = assert_error Streaks\find(@params.streak_id), "invalid streak"

          assert_unit_date @
          assert_error @streak\allowed_to_view @current_user

          assert_error tonumber(@params.user_id) == @current_user.id,
            "invalid user"

          @streak.streak_user = assert_error @streak\has_user @current_user,
            "not part of streak"

          existing = @streak.streak_user\submission_for_date @unit_date
          if existing
            @session.flash = "You've already submitted for #{@params.date}"
            return @write redirect_to: @url_for @streak

          @submittable_streaks = { @streak }
        else
          @submittable_streaks = @current_user\find_submittable_streaks!

      GET: =>
        @title = if #@submittable_streaks == 1
          "Submit to #{@submittable_streaks[1].title}"
        else
          "New submission"

        @suggested_tags = @current_user\suggested_submission_tags!
        render: "edit_submission"

      POST: capture_errors_json with_csrf =>
        submission = @flow("edit_submission")\create_submission!
        @session.flash = "Submission added"

        json: {
          success: true
          url: @url_for submission
        }

    }
  }

  [edit_submission: "/submission/:id/edit"]: require_login capture_errors {
    on_error: =>
      not_found

    respond_to {
      before: =>
        find_submission @
        assert_error @submission\allowed_to_edit(@current_user), "invalid submission"

      GET: =>
        @uploads = @submission\get_uploads!
        @streaks = @submission\get_streaks!
        @suggested_tags = @current_user\suggested_submission_tags!
        render: true

      POST: capture_errors_json with_csrf with_params {
        {"json", types.empty + types.any / true }
      }, (params) =>
        @flow("edit_submission")\edit_submission!

        if params.json
          {
            json: {
              success: true
              url: @url_for @submission
            }
          }
        else
          @session.flash = "Submission updated"
          redirect_to: @url_for @submission
    }
  }

  [delete_submission: "/submission/:id/delete"]: require_login capture_errors {
    on_error: => not_found
    respond_to {
      before: =>
        find_submission @
        assert_error @submission\allowed_to_edit(@current_user), "invalid submission"

      GET: =>
        render: true

      POST: =>
        @submission\delete!
        @session.flash = "Submission deleted"
        redirect_to: @url_for "index"
    }
  }

  [submission_streaks: "/submission/:id/streaks"]: require_login capture_errors_json respond_to {
    before: =>
      find_submission @
      @submits = @submission\get_streak_submissions!
      import Streaks from require "models"
      Streaks\include_in @submits, "streak_id"
      for submit in *@submits
        submit.submission = @submission

      if @submission\allowed_to_edit @current_user
        date = require "date"
        @submittable_streaks = @submission\get_user!\find_submittable_streaks date @submission.created_at

    GET: =>
      render: true

    POST: with_csrf with_params {
      {"action", types.one_of {"unsubmit", "submit"}}
      {"streak_id", types.db_id}
    }, (params) =>
      switch params.action
        when "submit"
          local streak
          assert_error @submittable_streaks, "no submittable streaks"
          for s in *@submittable_streaks
            if s.id == tonumber params.streak_id
              streak = s
              break

          assert_error streak, "invalid streak selected"
          assert_error streak\allowed_to_submit(@submission\get_user!), "not allowed to submit to streak"

          streak_submission = streak\submit @submission, @submission.created_at
          assert_error streak_submission, "failed to add submission to streak"
          @session.flash = "Added to streak"
        when "unsubmit"
          local streak_submission
          for submit in *@submits
            if submit.streak_id == tonumber params.streak_id
              streak_submission = submit
              break

          assert_error streak_submission, "invalid submission"
          assert_error streak_submission\allowed_to_moderate(@current_user),
            "invalid submission"

          streak_submission\delete!
          @session.flash = "Removed from streak"
        else
          yield_error "invalid action: #{params.action}"

      redirect_to: @url_for "submission_streaks", id: @submission.id

  }


  [submission_like: "/submission/:id/like"]: capture_errors_json respond_to {
    before: =>
      find_submission @

    GET: =>
      import SubmissionLikes from require "models"
      like = if @current_user
        SubmissionLikes\find {
          user_id: @current_user.id
          submission_id: @submission.id
        }

      json: @flow("submission")\like_props @submission, like

    POST: require_login with_csrf =>
      if @current_user\is_suspended!
        return json: {
          success: false
          count: @submission.likes_count
        }

      import SubmissionLikes, Notifications from require "models"
      like = SubmissionLikes\create {
        submission_id: @submission.id
        user_id: @current_user.id
      }

      if like and @current_user.id != @submission.user_id
        Notifications\notify_for @submission\get_user!, @submission, "like"

      @submission\refresh "likes_count"

      json: { success: not not like, count: @submission.likes_count }
  }

  [submission_unlike: "/submission/:id/unlike"]: require_login capture_errors_json with_csrf =>
    find_submission @

    import SubmissionLikes from require "models"

    params = {
      submission_id: @submission.id
      user_id: @current_user.id
    }

    success = if f = SubmissionLikes\find params
      f\delete!
      true

    @submission\refresh "likes_count"
    json: { success: success or false, count: @submission.likes_count }

  [submission_new_comment: "/submission/:id/comment"]: require_login capture_errors {
    on_error: => not_found

    respond_to {
      before: =>
        find_submission @
        assert_error @submission\allowed_to_comment(@current_user),
          "invalid user"

      GET: =>
        redirect_to: @url_for "view_submission", id: @submission.id

      POST: capture_errors_json with_csrf =>
        assert_error not @current_user\is_suspended!, "Could not post your comment, contact admin"

        comment = @flow("edit_comment")\create_comment!
        comment\get_user!

        SubmissionCommentList = require "widgets.submission_comment_list"
        widget = SubmissionCommentList comments: { comment }
        widget\include_helper @

        json: {
          success: true
          comment_id: comment.id
          comments_count: @submission.comments_count
          rendered: widget\render_to_string!
        }
    }
  }

  [edit_comment: "/submission-comment/:id/edit"]: require_login capture_errors_json respond_to {
    before: =>
      find_comment @
      assert_error @comment\allowed_to_edit(@current_user), "invalid comment"

    GET: =>
      submission = assert_error @comment\get_submission!, "invalid submission"
      redirect_to: @url_for submission

    POST: with_csrf =>
      @flow("edit_comment")\edit_comment!
      @comment\get_user!

      SubmissionCommentList = require "widgets.submission_comment_list"
      widget = SubmissionCommentList {
        comments: { @comment }
        submission: @comment\get_submission!
      }
      widget\include_helper @

      json: {
        success: true
        rendered: widget\render_to_string!
      }
  }

  [delete_comment: "/submission-comment/:id/delete"]: require_login capture_errors_json respond_to {
    POST: with_csrf =>
      find_comment @
      assert_error @comment\allowed_to_delete(@current_user), "invalid comment"

      deleted = @flow("edit_comment")\delete_comment!

      json: {
        success: true
        :deleted
        comments_count: @comment\get_submission!.comments_count
      }
  }

  [submission_comments: "/submission/:id/comments"]: capture_errors_json =>
    find_submission @
    assert_page @

    @submission_comments = @submission\find_comments(per_page: COMMENTS_PER_PAGE)\get_page @page
    @has_more = if @page == 1
      @submission.comments_count > COMMENTS_PER_PAGE
    else
      COMMENTS_PER_PAGE == #@submission_comments

    local widget

    widget = if @page == 1
      require("widgets.submission_commenter")!
    else
      require("widgets.submission_comment_list") {
        comments: @submission_comments
      }

    widget\include_helper @

    json: {
      comments_count: #@submission_comments
      has_more: @has_more
      success: true
      rendered: widget\render_to_string!
    }

  [submission_likes: "/submission/:id/likes"]: require_login =>
    import Followings from require "models"

    find_submission @
    pager = @submission\find_likes per_page: 100
    @likes = pager\get_page!

    Followings\load_for_users [l.user for l in *@likes], @current_user
    render: true
