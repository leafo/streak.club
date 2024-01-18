db = require "lapis.db"
import Model from require "lapis.db.model"

import insert_on_conflict_ignore from require "helpers.model"

date = require "date"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE streak_submissions (
--   streak_id integer NOT NULL,
--   submission_id integer NOT NULL,
--   submit_time timestamp without time zone NOT NULL,
--   user_id integer NOT NULL,
--   late_submit boolean DEFAULT false NOT NULL
-- );
-- ALTER TABLE ONLY streak_submissions
--   ADD CONSTRAINT streak_submissions_pkey PRIMARY KEY (streak_id, submission_id);
-- CREATE INDEX streak_submissions_streak_id_submit_time_idx ON streak_submissions USING btree (streak_id, submit_time);
-- CREATE INDEX streak_submissions_streak_id_user_id_submit_time_idx ON streak_submissions USING btree (streak_id, user_id, submit_time);
-- CREATE INDEX streak_submissions_submission_id_streak_id_submit_time_idx ON streak_submissions USING btree (submission_id, streak_id, submit_time);
--
class StreakSubmissions extends Model
  @primary_key: {"streak_id", "submission_id"}

  @relations: {
    {"user", belongs_to: "Users"}
    {"streak", belongs_to: "Streaks"}
    {"submission", belongs_to: "Submissions"}
  }

  @create: insert_on_conflict_ignore

  unit_number: =>
    @get_streak!\unit_number_for_date date @submit_time

  allowed_to_moderate: (user) =>
    return false unless user
    submission = @get_submission!
    return true if submission\allowed_to_edit user
    streak = @get_streak!
    return true if streak\allowed_to_edit user
    false

  -- might return false if user is no longer in streak
  get_streak_user: =>
    if @streak_user == nil
      import StreakUsers from require "models"
      @streak_user = StreakUsers\find {
        streak_id: @streak_id
        user_id: @user_id
      }

      @streak_user or= false

    @streak_user

  delete: =>
    if super!
      streak = @get_streak!
      streak\update {
        submissions_count: db.raw "submissions_count - 1"
      }, timestamp: false

      if streak_user = @get_streak_user!
        streak_user\update {
          submissions_count: db.raw "submissions_count + 1"
        }, timestamp: false

        streak_user\update_streaks!

      true
