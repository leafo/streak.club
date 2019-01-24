import Flow from require "lapis.flow"

import preload from require "lapis.db.model"

class StreakFlow extends Flow
  like_props: (submission, like) =>
    {
      submission_id: submission.id
      comment_url: @current_user and @url_for "submission_new_comment", id: submission.id
      likes_count: submission.likes_count
      likes_url: @url_for "submission_likes", id: submission.id
      like_url: @current_user and @url_for "submission_like", id: submission.id
      unlike_url: @current_user and @url_for("submission_unlike", id: submission.id)
      -- current_like: not not submission.submission_like
      current_like: not not like
      login_url: unless @current_user
        login_and_return_url @, @url_for submission
    }
