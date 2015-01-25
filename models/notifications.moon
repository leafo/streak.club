db = require "lapis.db"
import Model, enum from require "lapis.db.model"

import safe_insert from require "helpers.model"

class Notifications extends Model
  @timestamp: true

  @type: enum {
    comment: 1
  }

  @object_types: enum {
    submission: 1
  }

  @object_type_for_object: (object) =>
    switch object.__class.__name
      when "Submissions"
        @@object_types.submission
      else
        error "unknown object"

  @notify_for: (user, object, notify_type) =>
    return unless user
    notify_type = @type\for_db notify_type
    object_type = @object_type_for_object object

    create_params = {
      user_id: user.id
      object_type: object_type
      object_id: object.id
      count: 1
      type: notify_type
    }

    ident_params = {
      user_id: user.id
      object_type: object_type
      object_id: object.id
      type: notify_type
      seen: false
    }

    res = safe_insert @, create_params, ident_params

    return "create" if (res.affected_rows or 0) > 0

    db.update @table_name!, {
      count: db.raw "count + 1"
    }, ident_params

    "update"

