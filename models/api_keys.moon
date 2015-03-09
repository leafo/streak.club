
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


  @find_or_create: (user_id, source) =>
    source = @sources\for_db source

    key = unpack @select [[
      where user_id = ? and source = ?
    ]], user_id, source

    unless key
      key = @create user_id: user_id, :source

    key


  url_key: => @key

