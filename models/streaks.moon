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

  join: (user) =>
    import StreakUsers from require "models"
    res = safe_insert StreakUsers, streak_id: @id, user_id: user.id

    if res.affected_rows != 1
      return false

    @update users_count: db.raw "users_count + 1"
    StreakUsers\load (unpack res)

  leave: (user) =>
    if su = StreakUsers\find user_id: user.id, streak_id: streak.id
      su\delete!

  allowed_to_view: (user) =>
    true

  url_params: =>
    "view_streak", id: @id
