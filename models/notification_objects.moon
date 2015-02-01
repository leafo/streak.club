db = require "lapis.db"
import Model, enum from require "lapis.db.model"

import safe_insert from require "helpers.model"

class NotificationObjects extends Model
  @timestamp: true
  @primary_key: {"notification_id", "object_type", "object_type"}

  @object_types: enum {
    submission_comment: 1
    user: 2
  }

  @object_type_for_object: (object) =>
    switch object.__class.__name
      when "SubmissionComments"
        @@object_types.submission_comment
      when "Users"
        @@object_types.user
      else
        error "unknown object"

  @create_for_object: (notification_id, object) =>
    @create {
      object_type: @object_type_for_object object
      object_id: object.id
      :notification_id
    }

  @create: (opts={}) =>
    opts.object_type = @object_types\for_db opts.object_type
    safe_insert @, opts

