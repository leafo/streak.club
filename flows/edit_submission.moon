
db = require "lapis.db"

import yield_error from require "lapis.application"
import with_params from require "lapis.validate"
import filter_update from require "helpers.model"

import Flow from require "lapis.flow"
import Submissions from require "models"

types = require "lapis.validate.types"
shapes = require "helpers.shapes"

date = require "date"

null_empty = types.empty / db.NULL
make_empty_table = -> {}

class EditSubmissionFlow extends Flow
  -- NOTE: this can return an empty array if you are submitting only to account's personal streak
  get_submitting_streaks: with_params {
    {"submit_to", types.one_of {
      -- extract array of ids from set to array
      types.empty / make_empty_table
      types.map_of(types.db_id, -types.empty) / (t) -> [k for k in pairs t]
    }}
  }, (params) =>
    @submittable_streaks or= @current_user\find_submittable_streaks!
    submittable_by_id = {s.id, s for s in *@submittable_streaks}

    -- filter to streaks that are valid for submission
    streaks = for streak_id in *params.submit_to
      streak = submittable_by_id[streak_id]
      unless streak
        yield_error "You selected a streak that you cannot submit to"

      streak

    streaks

  validate_params: with_params {
    {"submission", types.params_shape {
      {"title", null_empty + types.limited_text 254 }
      {"description", null_empty + types.limited_text(1024 * 10) * -shapes.empty_html}
      {"user_rating", types.db_enum Submissions.user_ratings}

      {"tags", types.empty / "" + types.limited_text 512} -- empty string is used to strip tags
    }}
  }, (params) =>

    submission_params = params.submission

    @tags_str = submission_params.tags
    submission_params.tags = nil

    submission_params

  create_submission: =>
    import Streaks, Submissions from require "models"
    params = @validate_params!
    params.user_id = @current_user.id

    streaks = @get_submitting_streaks!
    for streak in *streaks
      if streak\is_hidden!
        params.hidden = true
        break

    @submission = Submissions\create params
    user_update = submissions_count: db.raw "submissions_count + 1"
    if @submission.hidden
      user_update.hidden_submissions_count = db.raw "hidden_submissions_count + 1"

    @current_user\update user_update

    for streak in *streaks
      submit_timestamp = if @unit_date
        submit_date = @streak\increment_date_by_unit @streak\truncate_date date @unit_date
        submit_date\addseconds -10
        submit_date\fmt Streaks.timestamp_format_str

      streak\submit @submission, submit_timestamp

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

  set_uploads: with_params {
    {"upload",
      -- NOTE: this would fail with exception if params_shape fails within
      -- array_of, due to error type mismatch, so we just have it yield an
      -- error
      types.empty / make_empty_table + shapes.map_to_array("upload_id") * types.array_of types.assert_error types.params_shape {
        {"upload_id", types.db_id}
        {"position", types.string\length(1,5) * types.pattern("^%d+$") / tonumber}
      }
    }
  }, (params) =>
    assert @submission, "submission needed to set uploads"
    import Uploads from require "models"

    uploads = params.upload
    table.sort uploads, (a,b) -> a.position < b.position

    Uploads\include_in uploads, "upload_id"

    -- filter ones that can be attached, edited
    uploads = for u in *uploads
      continue unless u.upload -- rows where no upload was found
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
