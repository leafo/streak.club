db = require "lapis.db"
import Model, enum, preload from require "lapis.db.model"

import insert_on_conflict_update from require "helpers.model"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE notifications (
--   id integer NOT NULL,
--   user_id integer NOT NULL,
--   type integer DEFAULT 0 NOT NULL,
--   object_type integer DEFAULT 0 NOT NULL,
--   object_id integer DEFAULT 0 NOT NULL,
--   count integer DEFAULT 0 NOT NULL,
--   seen boolean DEFAULT false NOT NULL,
--   created_at timestamp without time zone NOT NULL,
--   updated_at timestamp without time zone NOT NULL
-- );
-- ALTER TABLE ONLY notifications
--   ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);
-- CREATE INDEX notifications_user_id_seen_id_idx ON notifications USING btree (user_id, seen, id);
-- CREATE UNIQUE INDEX notifications_user_id_type_object_type_object_id_idx ON notifications USING btree (user_id, type, object_type, object_id) WHERE (NOT seen);
--
class Notifications extends Model
  @timestamp: true

  @relations: {
    {"user", belongs_to: "Users"}
    {"notification_objects", has_many: "NotificationObjects"}
    {"object", polymorphic_belongs_to: {
      [1]: {"submission", "Submissions"}
      [2]: {"submission_comment", "SubmissionComments"}
      [3]: {"user", "Users"}
      [4]: {"streak", "Streaks"}

      [5]: {"category", "Categories"}
      [6]: {"topic", "Topics"}
      [7]: {"post", "Posts"}
    }}
  }

  @types: enum {
    comment: 1
    mention: 2
    follow: 3
    like: 4
    join: 5
    approve_join: 6

    community_topic: 100 -- new topic in community you watch
    community_reply: 101 -- your post got a reply
    community_post: 102 -- new post in your topic
  }

  @get_relation_model: (name) =>
    -- allow community relations to be referenced
    require("models")[name] or require("community.models")[name]

  preloaders = {
    submission_comment: (notes) ->
      preload [n.object for n in *notes], "submission"

    category: (notes) ->
      preload [n.object for n in *notes]

    post: (notes) ->
      preload [n.object for n in *notes], "topic"
  }

  @preload_objects: (notifications) =>
    preload notifications, "object", "notification_objects"

    -- additional preloads
    by_object_type = {}
    for n in *notifications
      name = @object_types\to_name n.object_type
      by_object_type[name] or= {}
      table.insert by_object_type[name], n

    for object_type, notes in pairs by_object_type
      if pl = preloaders[object_type]
        pl notes

    notification_objects = {}
    for n in *notifications
      if objs = n.notification_objects
        for no in *objs
          table.insert notification_objects, no

    import NotificationObjects from require "models"
    NotificationObjects\preload_objects notification_objects
    notifications

  @notify_for: (user, object, notify_type, target_object) =>
    return unless user
    import NotificationObjects from require "models"

    notify_type = @types\for_db notify_type
    object_type = @object_type_for_object object

    notification = insert_on_conflict_update @, {
      user_id: user.id
      object_type: object_type
      object_id: object.id
      type: notify_type
      seen: false
    }, {
      count: 1
    }, {
      count: db.raw "notifications.count + 1"
      updated_at: db.format_date!
    }, {
      constraint: "(user_id, type, object_type, object_id) WHERE (NOT seen)"
    }

    if target_object
      NotificationObjects\create_for_object notification.id, target_object

    if notification.count == 1
      "create", notification
    else
      "update", notification

  -- TODO: make this decrement, then delete
  -- this blasts all unseen notifications for object on user
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
      when @@types.join
        if @count == 1
          "Somone joined "
        else
          "#{@count} people joined "
      when @@types.approve_join
        "You can now post in "
      when @@types.community_topic
        if @count == 1
          "A new topic was created in "
        else
          "#{@count} new topics were created in "
      when @@types.community_post
        if @count == 1
          "A new post was created in "
        else
          "#{@count} new posts were created in "
      when @@types.community_reply
        "You got a reply to "
      else
        error "unknown notification type (#{@type})"

  object_title: =>
    switch @object_type
      when @@object_types.submission
        @object.title or "your submission"
      when @@object_types.submission_comment
        "a comment"
      when @@object_types.user
        @object\name_for_display!
      when @@object_types.category
        @object\name_for_display!
      when @@object_types.post
        topic = @object\get_topic!
        "your post in #{topic\name_for_display!}"
      else
        @object.title or error "missing object title (#{@object_type})"

  mark_seen: =>
    @update seen: true

  show_join_usernames: =>
    return false unless @type == @@types.join
    return false unless @notification_objects
    return false unless next @notification_objects
    return false if #@notification_objects > 10
    true

