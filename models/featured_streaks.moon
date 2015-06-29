db = require "lapis.db"
import Model from require "lapis.db.model"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE featured_streaks (
--   streak_id integer NOT NULL,
--   "position" integer DEFAULT 0 NOT NULL,
--   created_at timestamp without time zone NOT NULL,
--   updated_at timestamp without time zone NOT NULL
-- );
-- ALTER TABLE ONLY featured_streaks
--   ADD CONSTRAINT featured_streaks_pkey PRIMARY KEY (streak_id);
-- CREATE INDEX featured_streaks_created_at_idx ON featured_streaks USING btree (created_at);
-- CREATE UNIQUE INDEX featured_streaks_position_idx ON featured_streaks USING btree ("position");
--
class FeaturedStreaks extends Model
  @primary_key: "streak_id"
  @timestamp: true

  @relations: {
    {"streak", belongs_to: "Streaks"}
  }

  @create: (opts={}) =>
    opts.position = db.raw "(select coalesce(max(position) + 1, 0) from featured_streaks)"
    Model.create @, opts

