db = require "lapis.db"
schema = require "lapis.db.schema"

import add_column, create_index, drop_index, drop_column from schema

{
  :boolean, :varchar, :integer, :text, :foreign_key, :double, :time, :numeric
} = schema.types

{
}

