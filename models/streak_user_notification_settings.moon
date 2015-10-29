
db = require "lapis.db"
import Model, enum from require "lapis.db.model"

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
  @primary_key: {"user_id", "streak_id"}

  @relations: {
    {"user", belongs_to: "Users"}
    {"streak", belongs_to: "Streaks"}
  }

  @frequencies: enum {
    sometimes: 1
    never: 2
    aggressive: 3
  }

  @create: (opts={}) =>
    opts.frequency = @frequencies\for_db opts.frequency or "sometimes"
    Model.create @, opts

  get_streak_user: =>
    if @streak_user == nil
      import StreakUsers from require "models"
      @streak_user = StreakUsers\find user_id: @user_id, streak_id: @streak.id
      @streak_user or= false

    @streak_user

  can_email: =>
    return false if @frequency == @@frequencies.never

    streak = @get_streak!
    streak_user = @get_streak_user!

    return false unless streak_user
    return false if streak.deleted
    true

  should_send_start_email: =>
    return false if @start_email_at
    true

  should_send_join_email: =>
    return false if @join_email_at
    true

  should_send_reminder_email: =>
    false

  should_send_late_submit_email: =>
    false


