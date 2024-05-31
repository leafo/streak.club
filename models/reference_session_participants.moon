db = require "lapis.db"
import Model from require "lapis.db.model"

import insert_on_conflict_update from require "helpers.model"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE reference_session_participants (
--   reference_session_id integer NOT NULL,
--   user_id integer NOT NULL,
--   created_at timestamp without time zone NOT NULL,
--   last_seen_at timestamp without time zone NOT NULL
-- );
-- ALTER TABLE ONLY reference_session_participants
--   ADD CONSTRAINT reference_session_participants_pkey PRIMARY KEY (reference_session_id, user_id);
--
class ReferenceSessionParticipants extends Model
  @relations: {
    {"reference_session", belongs_to: "ReferenceSessions"}
    {"user", belongs_to: "Users"}
  }

  @record_user: (reference_session, user) =>
    now = db.format_date!
    insert_on_conflict_update @, {
      reference_session_id: reference_session.id
      user_id: user.id
    }, {
      created_at: now
      last_seen_at: now
    }, {
      last_seen_at: now
    }
