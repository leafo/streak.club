import Model, enum from require "lapis.db.model"
import generate_key from require "helpers.keys"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE api_keys (
--   id integer NOT NULL,
--   key character varying(255) NOT NULL,
--   source integer DEFAULT 0 NOT NULL,
--   user_id integer NOT NULL,
--   created_at timestamp without time zone NOT NULL,
--   updated_at timestamp without time zone NOT NULL
-- );
-- ALTER TABLE ONLY api_keys
--   ADD CONSTRAINT api_keys_pkey PRIMARY KEY (id);
-- CREATE UNIQUE INDEX api_keys_key_idx ON api_keys USING btree (key);
-- CREATE INDEX api_keys_user_id_idx ON api_keys USING btree (user_id);
--
class ApiKeys extends Model
  @timestamp: true

  @relations: {
    {"user", belongs_to: "Users"}
  }

  @sources: enum {
    web: 1
    ios: 2
    android: 3
  }

  @create: (opts={}) =>
    opts.key or= generate_key 40
    opts.source = @sources\for_db opts.source
    Model.create @, opts


  @find_or_create: (user_id, source) =>
    source = @sources\for_db source

    key = unpack @select [[
      where user_id = ? and source = ?
    ]], user_id, source

    unless key
      key = @create user_id: user_id, :source

    key


  url_key: => @key

