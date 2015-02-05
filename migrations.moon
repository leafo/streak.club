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
    create_index "streak_users", "current_streak", "integer"
    create_index "streak_users", "longest_streak", "integer"

}


