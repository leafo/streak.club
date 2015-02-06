db = require "lapis.db"
import Model, enum from require "lapis.db.model"

config = require("lapis.config").get!

import thumb from require "helpers.images"

class Uploads extends Model
  @timestamp: true

  @types: enum {
    image: 1
    file: 2
  }

  @object_types: enum {
    submission: 1
  }

  @content_types = {
    jpg: "image/jpeg"
    jpeg: "image/jpeg"
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

    opts.extension or= opts.filename\match ".%.([%w_]+)$"
    opts.extension = opts.extension\lower! if opts.extension

    unless opts.extension
      return nil, "missing extensions"

    opts.type = if @content_types[opts.extension]
      "image"
    else
      "file"

    opts.type = @types\for_db opts.type

    Model.create @, opts

  allowed_to_download: (user) =>
    return false if @is_image!
    true

  allowed_to_edit: (user) =>
    return nil unless user
    return true if user\is_admin!
    user.id == @user_id

  belongs_to_object: (object) =>
    return false unless object.id == @object_id
    @@object_type_for_object(object) == @object_type

  path: =>
    "uploads/#{@@types[@type]}/#{@id}.#{@extension}"

  short_path: =>
    "#{@@types[@type]}/#{@id}.#{@extension}"

  is_image: =>
    @type == @@types.image

  is_audio: =>
    @extension == "mp3"

  image_url: (size="original") =>
    assert @is_image!, "upload not image"
    thumb @path!, size

  url_params: (_, ...) =>
    switch @type
      when @@types.image
        nil, @image_url ...
      else
        expires = ... or 15
        import signed_url from require "helpers.url"
        expire = os.time! + 15
        nil, signed_url "/download/#{@short_path!}?expires=#{expire}"

  delete: =>
    with super!
      import shell_quote, exec from require "helpers.shell"
      exec "rm #{shell_quote "#{config.user_content_path}/#{@path!}"}"

  increment: =>
    import DailyUploadDownloads from require "models"
    DailyUploadDownloads\increment @id
    @update downloads_count: db.raw "downloads_count + 1"

  increment_audio: =>
    import DailyAudioPlays from require "models"
    DailyAudioPlays\increment @id
