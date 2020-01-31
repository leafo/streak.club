db = require "lapis.db"
import Model, enum from require "lapis.db.model"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE related_streaks (
--   id integer NOT NULL,
--   streak_id integer NOT NULL,
--   other_streak_id integer NOT NULL,
--   type smallint NOT NULL,
--   reason text,
--   "position" integer DEFAULT 0 NOT NULL,
--   created_at timestamp without time zone NOT NULL,
--   updated_at timestamp without time zone NOT NULL
-- );
-- ALTER TABLE ONLY related_streaks
--   ADD CONSTRAINT related_streaks_pkey PRIMARY KEY (id);
-- CREATE INDEX related_streaks_other_streak_id_type_idx ON related_streaks USING btree (other_streak_id, type);
-- CREATE UNIQUE INDEX related_streaks_streak_id_type_other_streak_id_idx ON related_streaks USING btree (streak_id, type, other_streak_id);
--
class RelatedStreaks extends Model
  @timestamp: true

  @types: enum {
    related: 1
    substreak: 2
  }

  @relations: {
    {"streak", belongs_to: "Streaks"}
    {"other_streak", belongs_to: "Streaks"}
  }

  @create: (opts={}, ...) =>
    assert opts.streak_id
    assert opts.other_streak_id

    opts.type = @types\for_db opts.type

    opts.position or= db.raw db.interpolate_query "(
      select coalesce(max(position), 0) from #{db.escape_identifier @table_name!}
      where type = ? and streak_id = ?
    )", opts.type, opts.streak_id

    super opts, ...
