db = require "lapis.db"
import Model, enum from require "lapis.db.model"

class Streaks extends Model
  @timestamp: true

  @rates: enum {
    daily: 1
    weekly: 1
  }
