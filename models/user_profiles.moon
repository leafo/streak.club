import Model from require "lapis.db.model"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE user_profiles (
--   user_id integer NOT NULL,
--   bio text,
--   website text,
--   twitter text,
--   created_at timestamp without time zone NOT NULL,
--   updated_at timestamp without time zone NOT NULL,
--   password_reset_token character varying(255)
-- );
-- CREATE INDEX user_profiles_password_reset_token_idx ON user_profiles USING btree (password_reset_token) WHERE (password_reset_token IS NOT NULL);
--
class UserProfiles extends Model
  @primary_key: {"user_id"}
  @timestamp: true

  @relations: {
    {"user", belongs_to: "Users"}
  }

  -- without @
  twitter_handle: =>
    return unless @twitter
    @twitter\match("twitter.com/([^/]+)") or @twitter\match("^@(.+)") or @twitter

  format_website: =>
    return unless @website
    return @website if @website\match "^(%w+)://"
    "http://" .. @website
