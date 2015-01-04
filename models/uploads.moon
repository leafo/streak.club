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

  @preload_objects: (objects) =>
    ids_by_type = {}
    for object in *objects
      object_type = @object_type_for_object object
      ids_by_type[object_type] or= {}
      table.insert ids_by_type[object_type], object.id

    for object_type, ids in pairs ids_by_type
      uploads = @find_all ids, key: "object_id", where: {
        ready: true
        :object_type
      }

      uploads_by_object_id = {}
      for upload in *uploads
        uploads_by_object_id[upload.object_id] or= {}
        table.insert uploads_by_object_id[upload.object_id], upload

      for _, upload_list in pairs uploads_by_object_id
        table.sort upload_list, (a,b) ->
          a.position < b.position

      for object in *objects
        continue unless @object_type_for_object(object) == object_type
        object.uploads = uploads_by_object_id[object.id]

    true

  @object_type_for_object: (object) =>
    switch object.__class.__name
      when "Submissions"
        @object_types.submission
      else
        error "unknown object (#{object.__class.__name})"

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
    @@object_type_for_object(object) == @object_type

  path: =>
    "uploads/#{@@types[@type]}/#{@id}.#{@extension}"

  delete: =>
    with super!
      import shell_quote, exec from require "helpers.shell"
      os.execute "rm #{shell_quote "#{config.user_content_path}/#{@path!}"}"

