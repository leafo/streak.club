db = require "lapis.db"
import Model from require "lapis.db.model"

date = require "date"

import signed_url from require "helpers.url"

class StreakUsers extends Model
  @timestamp: true
  @primary_key: {"streak_id", "user_id"}

  @relations: {
    {"user", belongs_to: "Users"}
    {"streak", belongs_to: "Streaks"}
  }

  current_unit_submission: =>
    @submission_for_date date true

  -- UTC date
  submission_for_date: (d) =>
    streak = @get_streak!
    import Streaks, StreakSubmissions from require "models"
    format_str = "%Y-%m-%d %H:%M:%S"

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

  get_completed_units: =>
    import StreakSubmissions from require "models"
    unless @completed_units
      streak = @get_streak!

      fields = db.interpolate_query [[
        submission_id,
        (submit_time + ?::interval)::date submit_day
      ]], "#{streak.hour_offset} hours"

      res = StreakSubmissions\select [[
        where user_id = ? and streak_id = ?
      ]], @user_id, @streak_id, :fields

      @completed_units = {submit.submit_day, submit.submission_id for submit in *res}

    @completed_units

  submit_url: (r, date) =>
    import encode_query_string from require "lapis.util"
    base = r\url_for "new_streak_submission", id: @streak_id
    signed_url base .. "?" .. encode_query_string {
      expires: os.time! + 60*60*24*7
      user_id: @user_id
      :date
    }

  current_streak: =>
    streak = @get_streak!

  longest_streak: =>
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

