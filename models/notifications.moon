db = require "lapis.db"
import Model, enum from require "lapis.db.model"

import safe_insert from require "helpers.model"

class Notifications extends Model
  @timestamp: true

  @relations: {
    {"user", belongs_to: "Users"}
  }

  @types: enum {
    comment: 1
  }

  @object_types: enum {
    submission: 1
  }

  @preload_objects: (notifications) =>
    import Submissions from require "models"

    submission_notifications = [n for n in *notifications when n.object_type == @object_types.submission]
    Submissions\include_in submission_notifications, "object_id", {
      as: "object"
    }

    notifications

  @object_type_for_object: (object) =>
    switch object.__class.__name
      when "Submissions"
        @@object_types.submission
      else
        error "unknown object"

  @notify_for: (user, object, notify_type, target_object) =>
    return unless user
    import NotificationObjects from require "models"

    notify_type = @types\for_db notify_type
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

    if (res.affected_rows or 0) > 0
      notification = unpack res
      if target_object
        NotificationObjects\create_for_object notification.id, target_object

      return "create"

    db.update @table_name!, {
      count: db.raw "count + 1"
      updated_at: db.format_date!
    }, ident_params

    if notification = target_object and @find(ident_params)
      NotificationObjects\create_for_object notification.id, target_object

    "update"

  prefix: =>
    switch @type
      when @@types.comment
        if @count == 1
          "You got a comment on"
        else
          "You got #{@count} comments on"
      else
        error "unknown notification type"

  mark_seen: =>
    @update seen: true
