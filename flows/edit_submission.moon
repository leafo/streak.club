
db = require "lapis.db"

import assert_error from require "lapis.application"
import assert_valid from require "lapis.validate"
import trim_filter from require "lapis.util"
import filter_update from require "helpers.model"

import Flow from require "lapis.flow"

class EditSubmissionFlow extends Flow
  validate_params: =>
    assert_valid @params, {
      {"submission",  type: "table"}
    }

    submission_params = @params.submission
    trim_filter submission_params, {
      "title", "description"
    }

    assert_valid submission_params, {
      {"title", exists: true, max_length: 1024}
      {"description", exists: true, max_length: 1024 * 10}
    }

    submission_params

  create_submission: =>
    import Submissions from require "models"
    params = @validate_params!
    params.user_id = @current_user.id

    streak_user = assert_error @streak\has_user(@current_user),
      "user not in streak"

    submission = Submissions\create params
    submit = @streak\submit submission

    if submit
      streak_user\update submissions_count: db.raw "submissions_count + 1"
      @streak\update submissions_count: db.raw "submissions_count + 1"

    submission, submit

  edit_submission: =>
    import Submissions from require "models"
    assert @submission, "missing submission"
    params = @validate_params!
    filter_update @submission, params

    @set_uploads!

    if next params
      @submission\update params

  set_uploads: =>
    assert @submission, "submission needs to exist"
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
      continue unless u.upload\allowed_to_edit
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
