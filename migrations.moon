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
}

