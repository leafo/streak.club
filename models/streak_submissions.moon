db = require "lapis.db"
import Model from require "lapis.db.model"

class StreakSubmissions extends Model
  @primary_key: {"streak_id", "submission_id"}
