db = require "lapis.db"
schema = require "lapis.db.schema"

import
  create_table, add_column, create_index, drop_index, drop_column
  from schema

{
  :boolean, :varchar, :integer, :text, :foreign_key, :double, :time, :numeric, :serial
} = schema.types

{
  [1418544084]: =>
    create_table "users", {
      {"id", serial}
      {"username", varchar}
      {"encrypted_password", varchar}
      {"email", varchar}
      {"slug", varchar}

      {"last_active", time null: true}
      {"display_name", varchar null: true}
      {"avatar_url", varchar null: true}

      {"created_at", time}
      {"updated_at", time}

      "PRIMARY KEY (id)"
    }

    create_index "users", "slug", unique: true

    create_index "users", db.raw("lower(email)"), unique: true
    create_index "users", db.raw("lower(username)"), unique: true

  [1419494897]: =>
    create_table "streaks", {
      {"id", serial}
      {"user_id", foreign_key}
      {"title", varchar}

      {"short_description", text}
      {"description", text}

      {"published", boolean}
      {"deleted", boolean}

      {"start_date", time timezone: true}
      {"end_date", time timezone: true}

      {"rate", integer}

      {"users_count", integer}

      {"created_at", time}
      {"updated_at", time}

      "PRIMARY KEY (id)"
    }

    create_table "streak_users", {
      {"streak_id", foreign_key}
      {"user_id", foreign_key}
      {"submission_count", integer}

      {"created_at", time}
      {"updated_at", time}

      "PRIMARY KEY (streak_id, user_id)"
    }

    create_index "streak_users", "user_id"

  [1419752545]: =>
    create_table "submissions", {
      {"id", serial}
      {"user_id", foreign_key}

      {"title", varchar null: true}
      {"description", text}

      {"published", boolean default: true}
      {"deleted", boolean default: false}

      {"created_at", time}
      {"updated_at", time}

      "PRIMARY KEY (id)"
    }

    create_index "submissions", "user_id"

    create_table "streak_submissions", {
      {"streak_id", foreign_key}
      {"submission_id", foreign_key}
      {"submit_time", time}

      "PRIMARY KEY(streak_id, submission_id)"
    }

    create_index "streak_submissions", "submission_id", "streak_id", "submit_time"

  [1420172340]: =>
    add_column "streaks", "submission_count", integer

  [1420172477]: =>
    db.query "alter table streak_users rename column submission_count to submissions_count"
    db.query "alter table streaks rename column submission_count to submissions_count"

  [1420172985]: =>
    db.query "alter table streaks alter start_date type date"
    db.query "alter table streaks alter end_date type date"
    add_column "streaks", "hour_offset", integer

  [1420176500]: =>
    add_column "streak_submissions", "user_id", foreign_key null: true
    db.query "
      update streak_submissions
      set user_id = (select user_id from submissions where submissions.id = streak_submissions.submission_id)
    "

    db.query "alter table streak_submissions alter user_id drop default"

  [1420176501]: =>
    create_index "streak_submissions", "streak_id", "user_id", "submit_time"

  [1420181212]: =>
    create_table "uploads", {
      {"id", serial}
      {"user_id", foreign_key}
      {"type", integer}
      {"position", integer}

      {"object_type", integer null: true}
      {"object_id", foreign_key null: true}

      {"extension", varchar}

      {"filename", varchar}
      {"size", integer}

      {"ready", boolean}
      {"deleted", boolean} -- TODO: not using this yet

      {"data", text null: true}

      {"created_at", time}
      {"updated_at", time}

      "PRIMARY KEY (id)"
    }

    create_index "uploads", "user_id", "type"
    create_index "uploads", "object_type", "object_id", "position", when: "ready" -- 'when' fixed later

  [1420363626]: =>
    create_index "streak_submissions", "streak_id", "submit_time"

  [1420405517]: =>
    add_column "users", "submission_count", integer
    db.query "
      update users
      set submission_count = (select count(*) from submissions where user_id = users.id)
    "

  [1420424459]: =>
    create_table "submission_tags", {
      {"submission_id", foreign_key}
      {"slug", varchar}

      "PRIMARY KEY (submission_id, slug)"
    }

    create_index "submission_tags", "slug"

  [1420431193]: =>
    db.query "alter table submissions alter description drop not null"

  [1420433528]: =>
    create_table "followings", {
      {"source_user_id", foreign_key}
      {"dest_user_id", integer}

      {"created_at", time}
      {"updated_at", time}

      "PRIMARY KEY (source_user_id, dest_user_id)"
    }

    create_index "followings", "dest_user_id"

    add_column "users", "following_count", integer
    add_column "users", "followers_count", integer

  [1420437606]: =>
    db.query "alter table streak_submissions alter user_id set not null"


  [1420444339]: =>
    create_table "submission_likes", {
      {"submission_id", foreign_key}
      {"user_id", foreign_key}

      {"created_at", time}
      {"updated_at", time}

      "PRIMARY KEY (submission_id, user_id)"
    }

    create_index "submission_likes", "user_id", "created_at"
    add_column "submissions", "likes_count", integer

  [1420449446]: =>
    db.query "alter table users rename column submission_count to submissions_count"

  [1420710737]: =>
    require("lapis.exceptions.models").make_schema!

  [1420712611]: =>
    add_column "streaks", "publish_status", integer default: 2
    db.query "alter table streaks alter publish_status drop default"

  [1421223602]: =>
    add_column "users", "admin", boolean

  [1421473626]: =>
    add_column "streak_submissions", "late_submit", boolean

  [1421473830]: =>
    add_column "submissions", "user_rating", integer default: 2

  [1421477232]: =>
    add_column "submissions", "allow_comments", boolean default: true
    add_column "submissions", "comments_count", integer

    create_table "submission_comments", {
      {"id", serial}

      {"submission_id", foreign_key}
      {"user_id", foreign_key}

      {"body", text}

      {"edited_at", time null: true}
      {"deleted", boolean}

      {"created_at", time}
      {"updated_at", time}

      "PRIMARY KEY (id)"
    }

    create_index "submission_comments", "user_id", "id", where: "not deleted"
    create_index "submission_comments", "submission_id", "id", where: "not deleted"

  [1422135963]: =>
    create_table "user_profiles", {
      {"user_id", foreign_key}

      {"bio", text null: true}
      {"website", text null: true}
      {"twitter", text null: true}

      {"created_at", time}
      {"updated_at", time}
    }

    add_column "users", "streaks_count", integer
    add_column "users", "comments_count", integer

    db.query "
      update users set
        streaks_count = (select count(*) from streaks where user_id = users.id),
        comments_count = (select count(*) from submission_comments where user_id = users.id)
    "

  [1422142380]: =>
    add_column "users", "likes_count", integer
    db.query "
      update users set
        likes_count = (select count(*) from submission_likes where user_id = users.id)
    "

  [1422162067]: =>
    create_table "notifications", {
      {"id", serial}
      {"user_id", serial}

      {"type", integer}

      {"object_type", integer}
      {"object_id", integer}

      {"count", integer}

      {"seen", boolean}

      {"created_at", time}
      {"updated_at", time}

      "PRIMARY KEY (id)"
    }

    create_index "notifications", "user_id", "seen", "id"
    create_index "notifications", "user_id", "type", "object_type", "object_id", where: "not seen", unique: "true"

  [1422163531]: =>
    drop_index "uploads", "object_type", "object_id", "position"
    create_index "uploads", "object_type", "object_id", "position", where: "ready"

  [1422165197]: =>
    create_table "notification_objects", {
      {"notification_id", foreign_key}

      {"object_type", integer}
      {"object_id", integer}

      {"created_at", time}
      {"updated_at", time}

      "PRIMARY KEY (notification_id, object_type, object_id)"
    }

  [1422174951]: =>
    create_table "featured_streaks", {
      {"streak_id", foreign_key}
      {"position", integer}

      {"created_at", time}
      {"updated_at", time}

      "PRIMARY KEY (streak_id)"
    }

    create_index "featured_streaks", "streak_id", "position", unique: true

  [1422177586]: =>
    drop_index "featured_streaks", "streak_id", "position"
    create_index "featured_streaks", "position", unique: true

  [1422262875]: =>
    add_column "streaks", "category", integer

  [1422337369]: =>
    create_index "streaks", "publish_status", "users_count"

  [1422383477]: =>
    add_column "uploads", "downloads_count", integer

    create_table "daily_upload_downloads", {
      {"upload_id", foreign_key}
      {"date", "date NOT NULL"}
      {"count", integer}

      "PRIMARY KEY (upload_id, date)"
    }

  [1422606062]: =>
    create_index "followings", "source_user_id", "created_at"
    create_index "followings", "dest_user_id", "created_at"

  [1422641893]: =>
    create_index "streak_users", "streak_id", "created_at"

  [1422731265]: =>
    create_index "streaks", "user_id", "publish_status", "created_at"

  [1423123029]: =>
    add_column "streak_users", "current_streak", "integer"
    add_column "streak_users", "longest_streak", "integer"

  [1423209193]: =>
    create_table "daily_audio_plays", {
      {"upload_id", foreign_key}
      {"date", "date NOT NULL"}
      {"count", integer}

      "PRIMARY KEY (upload_id, date)"
    }

  [1423678535]: =>
    add_column "streaks", "twitter_hash", text null: true


  [1423712362]: =>
    create_table "featured_submissions", {
      {"submission_id", foreign_key}
      {"created_at", time}
      {"updated_at", time}

      "PRIMARY KEY (submission_id)"
    }

  [1425376265]: =>
    add_column "user_profiles", "password_reset_token", varchar null: true

  [1425545586]: =>
    create_table "api_keys", {
      {"id", serial}

      {"key", varchar}
      {"source", integer}
      {"user_id", foreign_key}

      {"created_at", time}
      {"updated_at", time}

      "PRIMARY KEY (id)"
    }

    create_index "api_keys", "key", unique: true
    create_index "api_keys", "user_id"

  [1425941245]: =>
    create_index "user_profiles", "password_reset_token", where: "password_reset_token is not null"

  [1426401405]: =>
    import Streaks from require "models"
    drop_column "streaks", "published"

    db.query "create extension pg_trgm;"
    db.query "create index steaks_title_idx on streaks using gin(title gin_trgm_ops) where not deleted and publish_status = #{Streaks.publish_statuses.published}"
    db.query "create index users_username_idx on users using gin(username gin_trgm_ops)"

  [1426439394]: =>
    add_column "streak_users", "last_submitted_at", time null: true
    db.query [[
      update streak_users set last_submitted_at = (
        select max(submit_time) from streak_submissions
        where streak_submissions.user_id = streak_users.user_id and streak_submissions.streak_id = streak_users.streak_id
      )
    ]]

  [1427955442]: =>
    create_index "featured_streaks", "created_at"

  [1431573586]: =>
    add_column "streaks", "late_submit_type", integer default: 1

  [1431917444]: =>
    add_column "submissions", "hidden", boolean
    add_column "users", "hidden_submissions_count", integer

    import Streaks from require "models"

    db.query "
      update submissions set hidden = true
      where exists(select 1 from streak_submissions
        inner join streaks on streak_submissions.streak_id = streaks.id
        where streak_submissions.submission_id = submissions.id and streaks.publish_status = ?)", Streaks.publish_statuses.hidden

    db.query "
      update users set hidden_submissions_count =
        (select count(*) from submissions where user_id = users.id and hidden)
    "

  [1431922768]: =>
    drop_index "submissions", "users"
    create_index "submissions", "user_id", "id"
    create_index "submissions", "user_id", "id", {
      where: "not hidden"
      index_name: "submissions_user_id_id_not_hidden_idx"
    }

  [1431928525]: =>
    add_column "users", "hidden_streaks_count", integer

    import Streaks from require "models"

    db.query "
      update users set hidden_streaks_count =
        (select count(*) from streaks where user_id = users.id and publish_status != ?)
    ", Streaks.publish_statuses.published

  [1432002497]: =>
    add_column "streak_users", "pending", boolean default: false
    add_column "streaks", "membership_type", integer default: 1


  [1432009672]: =>
    add_column "streaks", "pending_users_count", integer
    db.query "
      update streaks set pending_users_count =
        (select count(*) from streak_users
          where streak_id = streaks.id and pending)
    "

  [1432010515]: =>
    create_index "streak_users", "streak_id", "pending", "created_at"

  [1432190692]: =>
    add_column "users", "last_seen_feed_at", time null: true
    db.query "
      update users set last_seen_feed_at = last_active
    "

  [1432794242]: =>
    add_column "submission_tags", "user_id", foreign_key null: true
    db.query "update submission_tags
      set user_id = (select user_id from submissions where id = submission_tags.submission_id)"

    db.query "alter table streak_submissions alter user_id drop default"
    create_index "submission_tags", "user_id"

  [1433905410]: =>
    add_column "uploads", "storage_type", integer default: 1

  [1443740672]: =>
    add_column "streaks", "last_deadline_email_at", time null: true

  [1443753807]: =>
    create_table "user_ip_addresses", {
      {"user_id", foreign_key}
      {"ip", varchar}

      {"created_at", time}
      {"updated_at", time}

      "PRIMARY KEY (user_id, ip)"
    }

    create_index "user_ip_addresses", "ip"

  [1443853745]: =>
    add_column "users", "last_timezone", varchar null: true

  [1444151912]: =>
    add_column "streaks", "last_late_submit_email_at", time null: true
    add_column "streak_users", "late_submit_reminded_at", time null: true

}

