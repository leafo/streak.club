db = require "lapis.db"
import Model, enum from require "lapis.db.model"

config = require("lapis.config").get!

import thumb from require "helpers.images"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE uploads (
--   id integer NOT NULL,
--   user_id integer NOT NULL,
--   type integer DEFAULT 0 NOT NULL,
--   "position" integer DEFAULT 0 NOT NULL,
--   object_type integer,
--   object_id integer,
--   extension character varying(255) NOT NULL,
--   filename character varying(255) NOT NULL,
--   size bigint DEFAULT 0 NOT NULL,
--   ready boolean DEFAULT false NOT NULL,
--   deleted boolean DEFAULT false NOT NULL,
--   data json,
--   created_at timestamp without time zone NOT NULL,
--   updated_at timestamp without time zone NOT NULL,
--   downloads_count integer DEFAULT 0 NOT NULL,
--   storage_type integer DEFAULT 1 NOT NULL,
--   width integer,
--   height integer
-- );
-- ALTER TABLE ONLY uploads
--   ADD CONSTRAINT uploads_pkey PRIMARY KEY (id);
-- CREATE INDEX uploads_object_type_object_id_position_idx ON uploads USING btree (object_type, object_id, "position") WHERE ready;
-- CREATE INDEX uploads_user_id_type_idx ON uploads USING btree (user_id, type);
--
class Uploads extends Model
  @timestamp: true

  @relations: {
    {"user", belongs_to: "Users"}
    {"object", polymorphic_belongs_to: {
      [1]: {"submission", "Submissions"}
    }}
  }

  @types: enum {
    image: 1
    file: 2
  }

  @storage_types: enum {
    filesystem: 1
    google_cloud_storage: 2
  }

  @image_extensions: {
    jpg: true
    jpeg: true
    png: true
    gif: true
  }

  @content_types: {
    jpg: "image/jpeg"
    jpeg: "image/jpeg"
    png: "image/png"
    gif: "image/gif"
    mp3: "audio/mpeg"
    mp4: "video/mp4"
    ogg: "audio/ogg"
    oga: "audio/ogg"
    wav: "audio/wav"
    pdf: "application/pdf"
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

  @use_google_cloud_storage: =>
    -- if we have secret and storage
    local storage
    pcall ->
      storage = require "secret.storage"

    bucket = require("lapis.config").get!.storage_bucket
    storage and bucket

  @create: (opts={}) =>
    assert opts.user_id, "missing user id"
    assert opts.filename, "missing file name"

    opts.extension or= opts.filename\match ".%.([%w_]+)$"
    opts.extension = opts.extension\lower! if opts.extension

    unless opts.extension
      return nil, "missing extensions"

    opts.type = if @image_extensions[opts.extension]
      "image"
    else
      "file"

    opts.type = @types\for_db opts.type

    opts.storage_type = if @use_google_cloud_storage!
      @storage_types.google_cloud_storage
    else
      @storage_types.filesystem

    super opts

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

  is_filesystem: =>
    @storage_type == @@storage_types.filesystem

  is_google_cloud_storage: =>
    @storage_type == @@storage_types.google_cloud_storage

  image_url: (size="original") =>
    assert @is_image!, "upload not image"

    key = if @storage_type != 1
      "#{@storage_type},#{@bucket_key!}"
    else
      @path!

    thumb key, size

  save_url: (req) =>
    if @is_google_cloud_storage!
      req\url_for "save_upload", id: @id

  bucket_key: =>
    if @is_google_cloud_storage!
      "user_content/#{@path!}"

  upload_url_and_params: (req) =>
    switch @storage_type
      when @@storage_types.filesystem
        import signed_url from require "helpers.url"
        url = signed_url req\url_for("receive_upload", id: @id)
        url, {}
      when @@storage_types.google_cloud_storage
        storage = require "secret.storage"
        bucket = assert require("lapis.config").get!.storage_bucket, "missing bucket"
        storage\upload_url bucket, @bucket_key!, {
          size_limit: 20 * 1024^3
        }
      else
        error "unknown storage type"

  url_params: (_, ...) =>
    switch @type
      when @@types.image
        nil, @image_url ...
      else
        expires = ... or 15
        expire = os.time! + expires

        switch @storage_type
          when @@storage_types.filesystem
            import signed_url from require "helpers.url"
            nil, signed_url "/download/#{@short_path!}?expires=#{expire}"

          when @@storage_types.google_cloud_storage
            storage = require "secret.storage"
            bucket = require("lapis.config").get!.storage_bucket
            url = storage\signed_url bucket, @bucket_key!, expire
            -- TODO: workaround for cloud storage hardcoded http
            url = url\gsub "http://", "https://"
            nil, url

  delete: =>
    with super!
      return true unless @ready

      switch @storage_type
        when @@storage_types.filesystem
          import shell_escape from require "lapis.cmd.path"
          os.execute "rm '#{shell_escape "#{config.user_content_path}/#{@path!}"}'"
        when @@storage_types.google_cloud_storage
          storage = require "secret.storage"
          bucket = require("lapis.config").get!.storage_bucket
          storage\delete_file bucket, @bucket_key!

  increment: =>
    import DailyUploadDownloads from require "models"
    DailyUploadDownloads\increment @id
    @update downloads_count: db.raw "downloads_count + 1"

  increment_audio: =>
    import DailyAudioPlays from require "models"
    DailyAudioPlays\increment @id

  -- be careful, this might take up a lot of memory!
  get_file_contents: (...) =>
    switch @storage_type
      when @@storage_types.filesystem
        file = assert io.open "#{config.user_content_path}/#{@path!}"
        image_blob = assert file\read "*a"
        file\close!
        image_blob
      when @@storage_types.google_cloud_storage
        storage = require "secret.storage"
        bucket = require("lapis.config").get!.storage_bucket
        storage\get_file bucket, @bucket_key!, ...

  update_data: (update) =>
    new_data = @data and {k,v for k,v in pairs @data} or {}
    for k,v in pairs update
      new_data[k] = v

    import to_json from require "lapis.util"
    @update data: db.raw db.escape_literal to_json new_data

  thumbnail_dimensions: (width=600) =>
    return nil unless @is_image!

    width = 600
    local height

    -- don't upscale smaller things
    if @width
      width = math.min @width, width

    height = if @width and @height
      math.floor @height / @width * width

    -- don't let the height go crazy if they upload a strange aspect
    -- ratio
    if height
      height = math.min height, width * 3

    if width and height
      width, height, "#{width}x#{height}#"
    else
      width, height, "#{width}x#{height or ""}"

