db = require "lapis.db"
import Model from require "lapis.db.model"

date = require "date"

class StreakSubmissions extends Model
  @primary_key: {"streak_id", "submission_id"}

  @relations: {
    {"user", belongs_to: "Users"}
    {"streak", belongs_to: "Streaks"}
    {"submission", belongs_to: "Submissions"}
  }

  unit_number: =>
    @get_streak!\unit_number_for_date date @submit_time

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
      }

      if streak_user = @get_streak_user!
        streak_user\update_streaks!

      true
