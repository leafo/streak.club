db = require "lapis.db"

-- cumulative created per day
cumulative_created = (model, clause, field="created_at") ->
  clause = if clause
    "where " .. db.encode_clause clause

  table_name = if type(model) == "string"
    model
  else
    model\table_name!

  field = db.escape_identifier field

  db.query "select
    date_trunc('day', #{field})::date as date,
    sum(sum(1)) over (order by date_trunc('day', #{field})::date) as count
    from #{db.escape_identifier table_name}
    #{clause or ""}
    group by date_trunc('day', #{field})::date
  "


daily_created = (model, clause, field="created_at") ->
  clause = if clause
    "where " .. db.encode_clause clause

  table_name = if type(model) == "string"
    model
  else
    model\table_name!

  field = db.escape_identifier field

  db.query "select
    date_trunc('day', #{field})::date as date,
    count(*)
    from #{db.escape_identifier table_name}
    #{clause or ""}
    group by date_trunc('day', #{field})::date
    order by date asc
  "

{ :cumulative_created, :daily_created }
