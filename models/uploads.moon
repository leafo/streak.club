db = require "lapis.db"
import Model, enum from require "lapis.db.model"

class Uploads extends Model
  @root_path: "user_content"

  @timestamp: true

  @types: enum {
    image: 1
  }

  @object_types: enum {
    submission: 1
  }

  @content_types = {
    jpg: "image/jpeg"
    png: "image/png"
    gif: "image/gif"
  }

  @create: (opts={}) =>
    assert opts.user_id, "missing user id"
    assert opts.filename, "missing file name"

    opts.type = @types\for_db opts.type

    opts.extension or= opts.filename\match ".%.([%w_]+)$"
    opts.extension = opts.extension\lower! if opts.extension

    Model.create @, opts

  allowed_to_edit: (user) =>
    return nil unless user
    return true if user\is_admin!
    user.id == @user_id

  path: =>
    "uploads/#{@@types[@type]}/#{@id}.#{@extension}"

