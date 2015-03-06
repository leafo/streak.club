
db = require "lapis.db"
import Model, enum from require "lapis.db.model"

class ApiKeys extends Model
  @timestamp: true

  @sources: enum {
    web: 1
    ios: 1
  }

  generate: => error "not yet"
