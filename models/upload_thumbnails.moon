db = require "lapis.db"
import Model from require "lapis.db.model"

import insert_on_conflict_update from require "helpers.model"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE upload_thumbnails (
--   upload_id integer NOT NULL,
--   created_at timestamp without time zone NOT NULL,
--   updated_at timestamp without time zone NOT NULL,
--   width integer NOT NULL,
--   height integer NOT NULL,
--   data_url text NOT NULL
-- );
-- ALTER TABLE ONLY upload_thumbnails
--   ADD CONSTRAINT upload_thumbnails_pkey PRIMARY KEY (upload_id);
--
class UploadThumbnails extends Model
  @timestamp: true
  @primary_key: "upload_id"

  @create: (opts={}) =>
    insert_on_conflict_update @, {
      upload_id: assert opts.upload_id, "missing upload_id"
    }, opts
