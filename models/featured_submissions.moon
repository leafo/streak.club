db = require "lapis.db"
import Model from require "lapis.db.model"
import safe_insert from require "helpers.model"

class FeaturedSubmissions extends Model
  @primary_key: "submission_id"
  @timestamp: true

  @relations: {
    {"submission", belongs_to: "Submissions"}
  }

