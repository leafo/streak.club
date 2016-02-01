db = require "lapis.db"
import Model from require "lapis.db.model"

date = require "date"

import signed_url from require "helpers.url"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE streak_users (
--   streak_id integer NOT NULL,
--   user_id integer NOT NULL,
--   submissions_count integer DEFAULT 0 NOT NULL,
--   created_at timestamp without time zone NOT NULL,
--   updated_at timestamp without time zone NOT NULL,
--   current_streak integer,
--   longest_streak integer,
--   last_submitted_at timestamp without time zone,
--   pending boolean DEFAULT false NOT NULL
-- );
-- ALTER TABLE ONLY streak_users
--   ADD CONSTRAINT streak_users_pkey PRIMARY KEY (streak_id, user_id);
-- CREATE INDEX streak_users_streak_id_created_at_idx ON streak_users USING btree (streak_id, created_at);
-- CREATE INDEX streak_users_streak_id_pending_created_at_idx ON streak_users USING btree (streak_id, pending, created_at);
-- CREATE INDEX streak_users_user_id_idx ON streak_users USING btree (user_id);
--
class StreakUsers extends Model
  @timestamp: true
  @primary_key: {"streak_id", "user_id"}

  @relations: {
    {"user", belongs_to: "Users"}
    {"streak", belongs_to: "Streaks"}
  }

  @email_vars: (streak_users) =>
    vars = {}
    emails = for su in *streak_users
      vars[su.user.email] = {
        name_for_display: su.user\name_for_display!
      }
      su.user.email

    emails, vars

  current_unit_submission: =>
    @submission_for_date date true

  -- UTC date
  submission_for_date: (d) =>
    streak = @get_streak!
    import Streaks, StreakSubmissions from require "models"

    unit_start = streak\truncate_date d
    unit_end = streak\increment_date_by_unit date unit_start

    unit_start_formatted = unit_start\fmt(Streaks.timestamp_format_str)
    unit_end_formatted = unit_end\fmt(Streaks.timestamp_format_str)

    streak_submission = unpack StreakSubmissions\select "
      where streak_id = ? and
        user_id = ? and
        submit_time >= ? and
        submit_time < ?
      limit 1
    ", @streak_id, @user_id, unit_start_formatted, unit_end_formatted

    streak_submission

  -- return completed units indexed by local time date stamp
  get_completed_units: =>
    import StreakSubmissions from require "models"
    unless @completed_units
      streak = @get_streak!

      fields = "submission_id, " .. streak\_streak_submit_unit_group_field!
      res = StreakSubmissions\select [[
        where user_id = ? and streak_id = ?
      ]], @user_id, @streak_id, :fields

      @completed_units = {submit.submit_day, submit.submission_id for submit in *res}

    @completed_units

  submit_url: (r, date) =>
    import encode_query_string from require "lapis.util"
    base = r\url_for "new_submission"
    signed_url base .. "?" .. encode_query_string {
      expires: os.time! + 60*60*24*7
      user_id: @user_id
      streak_id: @streak_id
      :date
    }

  get_current_streak: =>
    streak = @get_streak!

    ago = streak\increment_date_by_unit date(true), -1
    if date(@last_submitted_at) > ago
      @current_streak
    else
      0

  get_longest_streak: =>
    @longest_streak

  count_current_streak: =>
    import Streaks from require "models"
    streak = @get_streak!
    completed = @get_completed_units!

    day = streak\truncate_date(date(true))\addhours streak.hour_offset
    day_stamp = day\fmt Streaks.day_format_str

    unless completed[day_stamp]
      -- start counting from yesterday since today is still available
      day\adddays -1

    current = 0
    while true
      day_stamp = day\fmt Streaks.day_format_str
      break unless completed[day_stamp]
      current += 1
      day\adddays -1

    current

  count_longest_streak: =>
    import Streaks from require "models"
    streak = @get_streak!
    completed = @get_completed_units!
    longest = 0
    current = nil
    for unit in streak\each_unit!
      stamp = date(unit)\addhours(streak.hour_offset)\fmt Streaks.day_format_str
      if completed[stamp]
        current or= 0
        current += 1
        longest = math.max current, longest
      else
        current = nil

    longest

  completion_rate: =>
    streak = @get_streak!
    completed = @get_completed_units!
    count = 0
    total = 0
    for unit in streak\each_unit_local!
      total += 1
      count += 1 if completed[unit]

    count/total if total > 0

  update_streaks: =>
    @update {
      longest_streak: @count_longest_streak!
      current_streak: @count_current_streak!
      last_submitted_at: db.raw "(
        select max(submit_time) from streak_submissions
        where streak_submissions.user_id = streak_users.user_id and streak_submissions.streak_id = streak_users.streak_id
      )"
    }, timestamp: false

  current_unit_number: =>
    joined = date @created_at
    streak = @get_streak!

    start = if joined < streak\start_datetime!
      streak\start_datetime!
    else
      joined

    streak\unit_span start, date true

  get_notification_settings: =>
    unless @notification_settings
      import StreakUserNotificationSettings from require "models"
      @notification_settings = StreakUserNotificationSettings\find(streak_id: @streak_id, user_id: @user_id)
      unless @notification_settings
        @notification_settings = StreakUserNotificationSettings\create streak_id: @streak_id, user_id: @user_id

    @notification_settings

