db = require "lapis.db"
import Model from require "lapis.db.model"

class StreakSubmissions extends Model
  @primary_key: {"streak_id", "submission_id"}

  @relations: {
    {"user", belongs_to: "User"}
    {"streak", belongs_to: "Streaks"}
    {"submission", belongs_to: "Submissions"}
  }

