db = require "lapis.db"
import Model from require "lapis.db.model"

import insert_on_conflict_ignore from require "helpers.model"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE submission_likes (
--   submission_id integer NOT NULL,
--   user_id integer NOT NULL,
--   created_at timestamp without time zone NOT NULL,
--   updated_at timestamp without time zone NOT NULL
-- );
-- ALTER TABLE ONLY submission_likes
--   ADD CONSTRAINT submission_likes_pkey PRIMARY KEY (submission_id, user_id);
-- CREATE INDEX submission_likes_user_id_created_at_idx ON submission_likes USING btree (user_id, created_at);
--
class SubmissionLikes extends Model
  @timestamp: true
  @primary_key: {"submission_id", "user_id"}

  @relations: {
    {"user", belongs_to: "Users"}
    {"submission", belongs_to: "Submissions"}
  }

  @create: (opts={}) =>
    assert opts.user_id, "missing user_id"
    assert opts.submission_id, "missing submission_id"

    if like = insert_on_conflict_ignore @, opts
      like\increment!
      like

  increment: (amount=1) =>
    amount = assert tonumber amount
    import Submissions, Users from require "models"

    Users\load(id: @user_id)\update {
      likes_count: db.raw "likes_count + #{amount}"
    }, timestamp: false

    Submissions\load(id: @submission_id)\update {
      likes_count: db.raw "likes_count + #{amount}"
    }, timestamp: false

  delete: =>
    if super!
      @increment -1
      true

