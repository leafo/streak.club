db = require "lapis.db"
import Model from require "lapis.db.model"

import safe_insert from require "helpers.model"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE daily_upload_downloads (
--   upload_id integer NOT NULL,
--   date date NOT NULL,
--   count integer DEFAULT 0 NOT NULL
-- );
-- ALTER TABLE ONLY daily_upload_downloads
--   ADD CONSTRAINT daily_upload_downloads_pkey PRIMARY KEY (upload_id, date);
--
class DailyUploadDownloads extends Model
  @primary_key: {"upload_id", "date"}

  @relations: {
    {"upload", belongs_to: "Uploads"}
  }

  @tmz: 0 -- utc

  @date: (days=0) =>
    time = os.time! + @tmz*60*60 + days*60*60*24
    os.date "!%Y-%m-%d", time

  @increment: (upload_id, amount=1) =>
    table = db.escape_identifier @table_name!
    amount = tonumber amount

    date = @date!
    res = safe_insert @, {
      :upload_id, :date, count: 1
    }, {
      :upload_id, :date
    }

    if (res.affected_rows or 0) > 0
      return "create"

    db.update @table_name!, {
      count: db.raw "count + 1"
      :date
    }, { :date }

    "update"
