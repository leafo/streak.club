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
    @get_streak!\unit_number_for_date date @submit_time

