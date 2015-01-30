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
    mention: 2
    follow: 3
    like: 4
  }

  @object_types: enum {
    submission: 1
    submission_comment: 2
    user: 3
  }

  @preload_objects: (notifications) =>
    import Submissions, SubmissionComments, Users from require "models"

    submission_notifications = [n for n in *notifications when n.object_type == @object_types.submission]
    Submissions\include_in submission_notifications, "object_id", {
      as: "object"
    }

    comment_notifications = [n for n in *notifications when n.object_type == @object_types.submission_comment]
    SubmissionComments\include_in comment_notifications, "object_id", {
      as: "object"
    }
    Submissions\include_in [n.object for n in *comment_notifications], "submission_id"

    user_notifications = [n for n in *notifications when n.object_type == @object_types.user]
    Users\include_in user_notifications, "object_id", {
      as: "object"
    }

    notifications

  @object_type_for_object: (object) =>
    switch object.__class.__name
      when "Submissions"
        @@object_types.submission
      when "SubmissionComments"
        @@object_types.submission_comment
      when "Users"
        @@object_types.user
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

      return "create", Notifications\load notification

    db.update @table_name!, {
      count: db.raw "count + 1"
      updated_at: db.format_date!
    }, ident_params

    if notification = target_object and @find(ident_params)
      NotificationObjects\create_for_object notification.id, target_object

    "update"

  -- TODO: make this decrement, then delete
  @undo_notify: (user, object, notify_type) =>
    return unless user

    import NotificationObjects from require "models"

    notify_type = @types\for_db notify_type
    object_type = @object_type_for_object object

    ident_params = {
      user_id: user.id
      object_type: object_type
      object_id: object.id
      type: notify_type
      seen: false
    }

    res = unpack db.query "
      delete from #{db.escape_identifier @table_name!}
      where #{db.encode_clause ident_params}
      returning id
    "

    if res
      db.query "
        delete from #{db.escape_identifier NotificationObjects\table_name!}
        where notification_id = ?
      ", res.id

    res

  prefix: =>
    switch @type
      when @@types.comment
        if @count == 1
          "You got a comment on"
        else
          "You got #{@count} comments on"
      when @@types.mention
        "You got mentioned in"
      when @@types.follow
        "You got followed by"
      when @@types.like
        if @count == 1
          "You got a like on"
        else
          "You got #{@count} likes on"
      else
        error "unknown notification type"

  object_title: =>
    switch @object_type
      when @@object_types.submission
        @object.title or "your submission"
      when @@object_types.submission_comment
        "a comment"
      when @@object_types.user
        @object\name_for_display!

  mark_seen: =>
    @update seen: true
