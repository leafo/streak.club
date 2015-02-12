db = require "lapis.db"

-- cumulative created per day
cumulative_created = (model) ->
  table_name = db.escape_identifier model\table_name!
  db.query "select
    date_trunc('day', created_at)::date as date,
    sum(sum(1)) over (order by date_trunc('day', created_at)::date) as count
    from #{table_name}
    group by date_trunc('day', created_at)::date
  "

{ :cumulative_created }
