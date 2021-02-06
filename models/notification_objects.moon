db = require "lapis.db"
import Model, enum from require "lapis.db.model"

import insert_on_conflict_ignore from require "helpers.model"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE notification_objects (
--   notification_id integer NOT NULL,
--   object_type integer DEFAULT 0 NOT NULL,
--   object_id integer DEFAULT 0 NOT NULL,
--   created_at timestamp without time zone NOT NULL,
--   updated_at timestamp without time zone NOT NULL
-- );
-- ALTER TABLE ONLY notification_objects
--   ADD CONSTRAINT notification_objects_pkey PRIMARY KEY (notification_id, object_type, object_id);
--
class NotificationObjects extends Model
  @timestamp: true
  @primary_key: {"notification_id", "object_type", "object_type"}

  @relations: {
    {"object", polymorphic_belongs_to: {
      [1]: {"submission_comment", "SubmissionComments"}
      [2]: {"user", "Users"}
      [3]: {"category", "Categories"}
      [4]: {"topic", "Topics"}
      [5]: {"post", "Posts"}
    }}
  }

  @get_relation_model: (name) =>
    -- allow community relations to be referenced
    require("models")[name] or require("community.models")[name]

  @create_for_object: (notification_id, object) =>
    @create {
      object_type: @object_type_for_object object
      object_id: object.id
      :notification_id
    }

  @create: (opts={}) =>
    opts.object_type = @object_types\for_db opts.object_type
    insert_on_conflict_ignore @, opts

