db = require "lapis.db"
import Model, enum from require "lapis.db.model"

config = require("lapis.config").get!

class Uploads extends Model
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

  belongs_to_object: (object) =>
    return false unless object.id == @object_id

    object_type = switch object.__class.__name
      when "Submissions"
        @@object_types.submission
      else
        error "unknown object (#{object.__class.__name})"

    object_type == @object_type



  path: =>
    "uploads/#{@@types[@type]}/#{@id}.#{@extension}"

  delete: =>
    with super!
      import shell_quote, exec from require "helpers.shell"
      os.execute "rm #{shell_quote "#{config.user_content_path}/#{@path!}"}"

