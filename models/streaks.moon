db = require "lapis.db"
import Model, enum from require "lapis.db.model"
import safe_insert from require "helpers.model"

class Streaks extends Model
  @timestamp: true

  @rates: enum {
    daily: 1
    weekly: 1
  }

  @create: (opts={}) =>
    assert opts.user_id, "missing user_id"
    opts.rate = @rates\for_db opts.rate
    Model.create @, opts

  has_user: (user) =>
    import StreakUsers from require "models"
    return nil unless user
    StreakUsers\find user_id: user.id, streak_id: @id

  join: (user) =>
    import StreakUsers from require "models"
    res = safe_insert StreakUsers, streak_id: @id, user_id: user.id

    if res.affected_rows != 1
      return false

    @update { users_count: db.raw "users_count + 1" }, timestamp: false
    StreakUsers\load (unpack res)

  leave: (user) =>
    if su = @has_user user
      res = su\delete!
      if res.affected_rows > 0
        @update { users_count: db.raw "users_count - 1" }, timestamp: false
        return true

    false

  allowed_to_view: (user) =>
    true

  allowed_to_edit: (user) =>
    return false unless user
    return true if user\is_admin!
    user.id == @user_id

  url_params: =>
    "view_streak", id: @id

  increment_date_by_unit: (date) =>
    switch @rate
      when @@rates.daily
        date\adddays 1
      else
        error "not yet"

  format_date_unit: (date) =>
    switch @rate
      when @@rates.daily
        date\fmt "%m/%d/%Y"
      else
        error "not yet"
