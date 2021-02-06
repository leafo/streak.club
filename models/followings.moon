db = require "lapis.db"
import Model from require "lapis.db.model"

import insert_on_conflict_ignore from require "helpers.model"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE followings (
--   source_user_id integer NOT NULL,
--   dest_user_id integer DEFAULT 0 NOT NULL,
--   created_at timestamp without time zone NOT NULL,
--   updated_at timestamp without time zone NOT NULL
-- );
-- ALTER TABLE ONLY followings
--   ADD CONSTRAINT followings_pkey PRIMARY KEY (source_user_id, dest_user_id);
-- CREATE INDEX followings_dest_user_id_created_at_idx ON followings USING btree (dest_user_id, created_at);
-- CREATE INDEX followings_dest_user_id_idx ON followings USING btree (dest_user_id);
-- CREATE INDEX followings_source_user_id_created_at_idx ON followings USING btree (source_user_id, created_at);
--
class Followings extends Model
  @primary_key: {"source_user_id", "dest_user_id"}
  @timestamp: true

  @relations: {
    {"source_user", belongs_to: "Users"}
    {"dest_user", belongs_to: "Users"}
  }

  @create: (opts={}) =>
    assert opts.source_user_id, "missing source_user_id"
    assert opts.dest_user_id, "missing dest_user_id"

    if follow = insert_on_conflict_ignore @, opts
      follow\increment!
      follow

  @load_for_users: (users, current_user) =>
    return unless current_user
    Followings\include_in users, "dest_user_id", {
      flip: true
      where: {
        source_user_id: current_user.id
      }
    }

  increment: (amount=1) =>
    amount = assert tonumber amount
    import Users from require "models"

    Users\load(id: @dest_user_id)\update {
      followers_count: db.raw "followers_count + #{amount}"
    }, timestamp: false

    Users\load(id: @source_user_id)\update {
      following_count: db.raw "following_count + #{amount}"
    }, timestamp: false

  delete: =>
    if super!
      @increment -1
      true

