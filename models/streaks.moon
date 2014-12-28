db = require "lapis.db"
import Model, enum from require "lapis.db.model"

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


  allowed_to_view: (user) =>
    true

  url_params: =>
    "view_streak", id: @id
