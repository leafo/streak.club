lapis = require "lapis.init"
config = require"lapis.config".get!

http = require "lapis.nginx.http"

import Uploads from require "models"
import image_signature, unb64_from_url from require "helpers.images"
import unescape from require "socket.url"

image_log = (msg) ->
  ngx.var.image_log = msg

time = ->
  ngx.update_time!
  ngx.now!

fmt_time = (t) ->
  "%0.2f"\format t

class extends lapis.Application
  layout: false

  "/*": =>
    splat = @params.splat
    splat = splat\match("^img/(.*)") or splat

    key, size, signature, ext = splat\match "^([^/]+)/([^/]+)/([^/]+)%.(%w+)$"

    unless key
      image_log "bad url"
      return status: 404, "not found"

    unless signature == image_signature "#{key}/#{size}"
      image_log "bad signature"
      return status: 404, "not found (bad signature)"

    key = unb64_from_url key

    storage_type, real_key = key\match "^(%d+),(.+)$"

    if storage_type
      storage_type = tonumber storage_type
      key = real_key
    else
      storage_type = Uploads.storage_types.filesystem

    start = time!
    local image_blob, load_err

    switch storage_type
      when Uploads.storage_types.filesystem
        file, load_err = io.open "#{config.user_content_path}/#{key}", "r"
        if file
          image_blob = file\read "*a"
          file\close!

      when Uploads.storage_types.google_cloud_storage
        storage = require "secret.storage"
        bucket_name = config.storage_bucket

        url = storage\signed_url bucket_name, key, os.time! + 10
        image_blob, status = http.request url

        if status != 200
          image_blob = nil
          load_err = "bucket #{status}"

    load_time = fmt_time time! - start

    unless image_blob
      image_log "not found (dl: #{load_time})"
      return status: 404, "not found (#{load_err})"

    if size != "original" and ext != "gif"
      start = time!
      import load_image_from_blob from require "magick"
      image = assert load_image_from_blob image_blob

      image\auto_orient!
      image\thumb (unescape size)

      image_blob = image\get_blob!
      resize_time = fmt_time time! - start
      image_log "resize #{key} (load: #{load_time}) (res: #{resize_time})"
    else
      image_log "skip #{key} (load: #{load_time})"

    content_type: Uploads.content_types[ext], image_blob

