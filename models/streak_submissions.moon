db = require "lapis.db"
import Model from require "lapis.db.model"

date = require "date"

class StreakSubmissions extends Model
  @primary_key: {"streak_id", "submission_id"}

  @relations: {
    {"user", belongs_to: "User"}
    {"streak", belongs_to: "Streaks"}
    {"submission", belongs_to: "Submissions"}
  }

  unit_number: =>
    streak = @get_streak!
    start = streak\start_datetime!
    current = streak\truncate_date date @submit_time
    error "not yet for week" if streak.rate != streak.__class.rates.daily
    date.diff(current, start)\spandays!
