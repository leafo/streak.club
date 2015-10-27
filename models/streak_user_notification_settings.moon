
db = require "lapis.db"
import Model from require "lapis.db.model"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE streak_user_notification_settings (
--   user_id integer NOT NULL,
--   streak_id integer NOT NULL,
--   email_reminders boolean DEFAULT true NOT NULL,
--   late_submit_reminded_at timestamp without time zone,
--   join_email_at timestamp without time zone,
--   start_email_at timestamp without time zone
-- );
-- ALTER TABLE ONLY streak_user_notification_settings
--   ADD CONSTRAINT streak_user_notification_settings_pkey PRIMARY KEY (user_id, streak_id);
--
class StreakUserNotificationSettings extends Model


