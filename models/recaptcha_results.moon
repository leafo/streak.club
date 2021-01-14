db = require "lapis.db"
import Model, enum from require "lapis.db.model"

import insert_on_conflict_update, db_json from require "helpers.model"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE recaptcha_results (
--   id integer NOT NULL,
--   object_type smallint NOT NULL,
--   object_id integer NOT NULL,
--   action smallint NOT NULL,
--   data json NOT NULL,
--   created_at timestamp without time zone NOT NULL,
--   updated_at timestamp without time zone NOT NULL
-- );
-- ALTER TABLE ONLY recaptcha_results
--   ADD CONSTRAINT recaptcha_results_pkey PRIMARY KEY (id);
-- CREATE UNIQUE INDEX recaptcha_results_object_type_object_id_action_idx ON recaptcha_results USING btree (object_type, object_id, action);
--
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
