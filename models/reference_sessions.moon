db = require "lapis.db"
import Model from require "lapis.db.model"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE reference_sessions (
--   id integer NOT NULL,
--   uid uuid DEFAULT gen_random_uuid(),
--   user_id integer NOT NULL,
--   streak_id integer,
--   title text NOT NULL,
--   created_at timestamp without time zone NOT NULL,
--   updated_at timestamp without time zone NOT NULL,
--   data json
-- );
-- ALTER TABLE ONLY reference_sessions
--   ADD CONSTRAINT reference_sessions_pkey PRIMARY KEY (id);
-- CREATE UNIQUE INDEX reference_sessions_uid_idx ON reference_sessions USING btree (uid);
--
class ReferenceSessions extends Model
  @timestamp: true
  @relations: {
    {"user", belongs_to: "Users"}
    {"streak", belongs_to: "Streaks"}
    {"participants", has_many: "ReferenceSessionParticipants"}
    {"active_participants", has_many: "ReferenceSessionParticipants", where: db.clause {
      {"last_seen_at > now() at time zone 'utc' - '10 seconds'::interval"}
    }}

    { "uploads",
      has_many: "Uploads",
      key: "object_id"
      order: "created_at asc"
      where: {
        object_type: 2
        ready: true
      }
    }
  }

  url_params: =>
    "reference_session", { uid: @uid }

  name_for_display: =>
    @title or "Session #{@uid}"

  record_user: (user) =>
    import ReferenceSessionParticipants from require "models"
    ReferenceSessionParticipants\record_user @, user
