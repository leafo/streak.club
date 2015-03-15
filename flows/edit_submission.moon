
db = require "lapis.db"

import assert_error, yield_error from require "lapis.application"
import assert_valid from require "lapis.validate"
import trim_filter from require "lapis.util"
import filter_update from require "helpers.model"
import is_empty_html from require "helpers.html"

import Flow from require "lapis.flow"

date = require "date"

class EditSubmissionFlow extends Flow
  get_submitting_streaks: =>
    @submittable_streaks or= @current_user\get_submittable_streaks!
    submittable_by_id = {s.id, s for s in *@submittable_streaks}

    unless @params.submit_to
      yield_error "you must choose a streak to submit to"

    assert_valid @params, {
      {"submit_to", type: "table"}
    }

    streaks = for id in pairs @params.submit_to
      with streak = submittable_by_id[tonumber id]
        continue unless streak

    unless next streaks
      yield_error "you must choose a streak to submit to"

    streaks

  validate_params: =>
    import Submissions from require "models"
    assert_valid @params, {
      {"submission", type: "table"}
    }

    submission_params = @params.submission
    trim_filter submission_params, {
      "title", "description", "tags", "user_rating"
    }

    assert_valid submission_params, {
      {"title", optional: true, max_length: 1024}
      {"description", optional: true, max_length: 1024 * 10}
      {"user_rating", one_of: Submissions.user_ratings}
    }

    @tags_str = submission_params.tags or ""
    submission_params.tags = nil

    if is_empty_html submission_params.description or ""
      submission_params.description = nil

    submission_params.title or= db.NULL
    submission_params.description or= db.NULL
    submission_params.user_rating = Submissions.user_ratings\for_db submission_params.user_rating

    submission_params

  create_submission: =>
    import Streaks, Submissions from require "models"
    params = @validate_params!
    params.user_id = @current_user.id

    streaks = @get_submitting_streaks!

    @submission = Submissions\create params
    @current_user\update submissions_count: db.raw "submissions_count + 1"

    for streak in *streaks
      submit_timestamp = if @unit_date
        submit_date = @streak\increment_date_by_unit @streak\truncate_date date @unit_date
        submit_date\addseconds -10
        submit_date\fmt Streaks.timestamp_format_str

      submit = streak\submit @submission, submit_timestamp
      if submit
        streak.streak_user\update submissions_count: db.raw "submissions_count + 1"
        streak.streak_user\update_streaks!

        streak\update submissions_count: db.raw "submissions_count + 1"

    @set_uploads!
    @set_tags!
    @submission

  edit_submission: =>
    import Submissions from require "models"
    assert @submission, "missing submission"
    params = @validate_params!
    filter_update @submission, params

    @set_uploads!
    @set_tags!

    if next params
      @submission\update params

  set_tags: =>
    assert @submission, "submission needed to set tags"

    @submission\set_tags @tags_str

  set_uploads: =>
    assert @submission, "submission needed to set uploads"
    import Uploads from require "models"

    assert_valid @params, {
      {"upload", optional: true, type: "table"}
    }

    uploads = @params.upload or {}

    uploads = for id, upload in pairs uploads
      trim_filter upload
      assert_valid upload, {
        {"position", is_integer: true}
      }

      {
        upload_id: tonumber id
        position: tonumber upload.position
      }

    table.sort uploads, (a,b) ->
      a.position < b.position

    Uploads\include_in uploads, "upload_id"
    -- filter ones that can be attached, edited
    uploads = for u in *uploads
      continue unless u.upload\allowed_to_edit @current_user
      continue if u.upload.object_id and not u.upload\belongs_to_object @submission
      u

    existing_uploads = @submission\get_uploads!
    existing_by_id = {u.id, u for u in *existing_uploads}

    for u in *uploads
      to_update = {
        object_type: Uploads.object_types.submission
        object_id: @submission.id
        position: u.position
      }

      filter_update u.upload, to_update
      if next to_update
        u.upload\update to_update

      existing_by_id[u.upload_id] = nil

    for _, old_upload in pairs existing_by_id
      old_upload\delete!

    true
