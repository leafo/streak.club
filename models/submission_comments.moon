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

  allowed_to_delete: (user) =>
    return true if @allowed_to_edit user
    if user and user.id == @get_submission!.user_id
      return true
    false

