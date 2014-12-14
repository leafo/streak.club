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

}

