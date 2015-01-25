db = require "lapis.db"
import Model from require "lapis.db.model"

class FeaturedStreaks extends Model
  @primary_key: "streak_id"
  @timestamp: true

  @create: (opts={}) =>
    opts.position = db.raw "(select coalesce(max(position) + 1, 0) from featured_streaks)"
    Model.create @, opts

