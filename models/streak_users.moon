db = require "lapis.db"
import Model from require "lapis.db.model"

date = require "date"

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
    import StreakSubmissions from require "models"
    format_str = "%Y-%m-%d %H:%M:%S"

    left = streak\truncate_date d
    right = streak\increment_date_by_unit date left

    streak_submission = unpack StreakSubmissions\select "
      where streak_id = ? and
        user_id = ? and
        submit_time >= ? and
        submit_time < ?
      limit 1
    ", @streak_id, @user_id, left\fmt(format_str), right\fmt(format_str)

    streak_submission

  completed_units: =>
    import StreakSubmissions from require "models"
    streak = @get_streak!

    fields = db.interpolate_query [[
      submission_id,
      (submit_time + ?::interval)::date submit_day
    ]], "#{streak.hour_offset} hours"

    res = StreakSubmissions\select [[
      where user_id = ? and streak_id = ?
    ]], @user_id, @streak_id, :fields

    {submit.submit_day, submit.submission_id for submit in *res}

