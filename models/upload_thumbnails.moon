db = require "lapis.db"
import Model from require "lapis.db.model"

import insert_on_conflict_update from require "helpers.model"

class UploadThumbnails extends Model
  @timestamp: true
  @primary_key: "upload_id"

  @create: (opts={}) =>
    insert_on_conflict_update @, {
      upload_id: assert opts.upload_id, "missing upload_id"
    }, opts
