b = require "lapis.db"
import Model from require "lapis.db.model"

class SubmissionComments extends Model
  @timestamp: true

  @relations: {
    {"user", belongs_to: "Users"}
    {"submission", belongs_to: "Submissions"}
  }

  allowed_to_edit: (user) =>
    return false unless user
    return true if user\is_admin!
    user.id == @user_id
