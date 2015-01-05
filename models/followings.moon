db = require "lapis.db"
import Model from require "lapis.db.model"

import safe_insert from require "helpers.model"

class Followings extends Model
  @primary_key: {"source_user_id", "dest_user_id"}
  @timestamp: true

  @create: (opts={}) =>
    assert opts.source_user_id, "missing source_user_id"
    assert opts.dest_user_id, "missing dest_user_id"

    res = safe_insert @, opts

    if res.affected_rows != 1
      return false

    with Followings\load (unpack res)
      @increment!

  increment: (amount=1) =>
    amount = assert tonumber amount
    import Users from require "models"

    Users\load(id: @dest_user_id)\update {
      followers_count: db.raw "followers_count + #{amount}"
    }, timestamp: false

    Users\load(id: @source_user_id)\update {
      following_count: db.raw "following_count + #{amount}"
    }, timestamp: false

  delete: =>
    with out = super!
      if out.affected_rows and out.affected_rows > 0
        @increment -1
