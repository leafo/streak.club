b = require "lapis.db"
import Model from require "lapis.db.model"

class SubmissionComments extends Model
  @timestamp: true

  @relations: {
    {"user", belongs_to: "Users"}
    {"submission", belongs_to: "Submissions"}
  }

