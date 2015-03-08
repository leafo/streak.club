
db = require "lapis.db"
import Model, enum from require "lapis.db.model"
import generate_key from require "helpers.keys"

class ApiKeys extends Model
  @timestamp: true

  @relations: {
    {"user", belongs_to: "Users"}
  }

  @sources: enum {
    web: 1
    ios: 2
    android: 3
  }

  @create: (opts={}) =>
    opts.key or= generate_key 40
    opts.source = @sources\for_db opts.source
    Model.create @, opts

  url_key: => @key

