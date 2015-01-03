db = require "lapis.db"
import Model, enum from require "lapis.db.model"

class Uploads extends Model
  @timestamp: true

  @types: enum {
    image: 1
  }

  @object_types: enum {
    submission: 1
  }

  @create: (opts={}) =>
    assert opts.user_id, "missing user id"
    opts.type = @types\for_db opts.type
    Model.create @, opts

