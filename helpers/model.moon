db = require "lapis.db"
import concat from table

-- safe_insert Model, {color: true, id: 100}, {id: 100}
safe_insert = (data, check_cond=data) =>
  table_name = db.escape_identifier @table_name!

  if @timestamp
    data = {k,v for k,v in pairs data}
    time = db.format_date!
    data.created_at = time
    data.updated_at = time

  columns = [key for key in pairs data]
  values = [db.escape_literal data[col] for col in *columns]

  for i, col in ipairs columns
    columns[i] = db.escape_identifier col

  q = concat {
    "insert into"
    table_name
    "("
    concat columns, ", "
    ")"
    "select"
    concat values, ", "
    "where not exists ( select 1 from"
    table_name
    "where"
    db.encode_clause check_cond
    ") returning *"
  }, "  "

  db.query q

-- remove fields that haven't changed
filter_update = (model, update) ->
  for key,val in pairs update
    if model[key] == val
      update[key] = nil

    if val == db.NULL and model[key] == nil
      update[key] = nil

  update

update_cond = (update, check) =>
  primary = @_primary_cond!
  for k,v in pairs check
    primary[k] = v

  res = db.update @@table_name!, update, primary

  res.affected_rows and res.affected_rows > 0

transition = (col, before, after) =>
  assert col, "missing col"
  assert before, "missing before"
  assert after, "missing after"

  update_cond @, { [col]: after }, { [col]: before }

{ :safe_insert, :filter_update, :update_cond, :transition }
