db = require "lapis.db"
import Model from require "lapis.db.model"

class StreakUsers extends Model
  @timestamp: true
  @primary_key: {"streak_id", "user_id"}

  @relations: {
    {"user", belongs_to: "Users"}
    {"streak", belongs_to: "Streaks"}
  }

  current_unit_submission: =>
    streak = @get_streak!


