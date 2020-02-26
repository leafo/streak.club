db = require "lapis.db"
import Model, enum from require "lapis.db.model"

import insert_on_conflict_update, db_json from require "helpers.model"

class RecaptchaResults extends Model
  @timestamp: true

  @relations: {
    {"object", polymorphic_belongs_to: {
      {"user", "Users"}
    }}
  }

  @actions: enum {
    register: 1
  }

  @create: (opts) =>
    if opts.data
      opts.data = db_json opts.data

    opts.action = @actions\for_db opts.action
    opts.object_type = @object_types\for_db opts.object_type

    insert_on_conflict_update @, {
      object_type: opts.object_type
      object_id: assert opts.object_id, "missing object_id"
      action: opts.action
    }, opts
