db = require "lapis.db"
import Model from require "lapis.db.model"

class StreakUsers extends Model
  @primary_key: {"streak_id", "user_id"}
