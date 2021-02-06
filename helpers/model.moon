db = require "lapis.db"
json = require "cjson"
import concat, insert from table

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


insert_on_conflict_ignore = (model, opts) ->
  import encode_values, encode_assigns from require "lapis.db"

  full_insert = {}

  if opts
    for k,v in pairs opts
      full_insert[k] = v

  if model.timestamp
    d = db.format_date!
    full_insert.created_at = d
    full_insert.updated_at = d

  buffer = {
    "insert into "
    db.escape_identifier model\table_name!
    " "
  }

  encode_values full_insert, buffer

  insert buffer, " on conflict do nothing returning *"

  q = concat buffer
  res = db.query q

  if res.affected_rows and res.affected_rows > 0
    model\load res[1]
  else
    nil, res

insert_on_conflict_update = (model, primary, create, update, opts) ->
  import encode_values, encode_assigns from require "lapis.db"

  full_insert = {k,v for k,v in pairs primary}

  if create
    for k,v in pairs create
      full_insert[k] = v

  full_update = update or {k,v for k,v in pairs full_insert when not primary[k]}

  if model.timestamp
    d = db.format_date!
    full_insert.created_at or= d
    full_insert.updated_at or= d
    full_update.updated_at or= d

  buffer = {
    "insert into "
    db.escape_identifier model\table_name!
    " "
  }

  encode_values full_insert, buffer

  if opts and opts.constraint
    insert buffer, " on conflict "
    insert buffer, opts.constraint
    insert buffer, " do update set "
  else
    insert buffer, " on conflict ("

    assert next(primary), "no primary constraint for insert on conflict update"

    for k in pairs primary
      insert buffer, db.escape_identifier k
      insert buffer, ", "

    buffer[#buffer] = ") do update set " -- remove ,

  encode_assigns full_update, buffer

  insert buffer, " returning *"

  if opts and opts.return_inserted
    insert buffer, ", xmax = 0 as inserted"

  q = concat buffer
  res = db.query q

  if res.affected_rows and res.affected_rows > 0
    model\load res[1]
  else
    nil, res

-- this will ensure json value is decoded after update/insert by using db.raw
-- eg. thing\update data: db_json {hello: "world"}
db_json = (v) ->
  if type(v) == "string"
    v
  else
    db.raw db.escape_literal json.encode v


{ :filter_update, :update_cond, :transition, :insert_on_conflict_update, :insert_on_conflict_ignore, :db_json }
