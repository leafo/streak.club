
import $ from "main/jquery"
import {event as sendEvent, with_csrf} from "main/util"

import {format_bytes} from "main/util"

export create_video_thumbnail_from_url = (url) ->
  v = document.createElement('video')
  v.crossOrigin = "anonymous"
  v.src = url

  $.Deferred (d) ->
    thumbnail_size = 48

    v.addEventListener "seeked", ->
      {data_url, width, height} = create_video_thumbnail v
      d.resolve data_url, width, height, v

    v.currentTime = 1


export create_video_thumbnail = (video) ->
  thumbnail_size = 48

  canvas = document.createElement('canvas')
  canvas.width = thumbnail_size
  canvas.height = Math.floor canvas.width * video.videoHeight / video.videoWidth

  ctx = canvas.getContext('2d')

  # we draw it twice to pervent alpha bleed around blurred edges
  ctx.drawImage(video, 0, 0, canvas.width, canvas.height)

  ctx.filter = 'saturate(150%) blur(1px) contrast(120%)'
  ctx.drawImage(video, 0, 0, canvas.width, canvas.height)

  data_url = canvas.toDataURL("image/jpeg", 0.6)
  console.log data_url

  {
    data_url
    width: canvas.width
    height: canvas.height
  }


# NOTE: all files pass through here, so we should resolve null for non-images
# NOTE: this also generates thumbnail for video file
export get_image_dimensions = (file) ->
  $.Deferred (d) ->
    switch file.type
      when "video/mp4"
        if URL?.createObjectURL?
          src = URL.createObjectURL file
          el = document.createElement "video"

          el.src = src
          el.currentTime = 1
          el.addEventListener "seeked", ->
            thumbnail = create_video_thumbnail el
            d.resolve el.videoWidth, el.videoHeight, thumbnail

          el.onerror = -> d.resolve null
      else
        if URL?.createObjectURL?
          src = URL.createObjectURL file

          image = new Image
          image.src = src

          image.onload = -> d.resolve image.width, image.height
          image.onerror = -> d.resolve null
        else if window.createImageBitmap
          createImageBitmap(file).then (bitmap) =>
            d.resolve(bitmap.width, bitmap.height)
          , => d.resolve null
        else
          # no way to detect image size
          d.resolve null



export class Upload
  constructor: (@data, @on_update) ->

  upload_params: => @_upload_params ||= {}

  set_upload_params: (obj) =>
    return unless obj
    params = @upload_params()

    for k,v of obj
      params[k] = v

    params

  set_save_url: (@save_url) =>

  start_upload: (action) ->
    throw "missing file" unless @data.file

    @uploading = true
    @on_update?()

    form_data = new FormData()
    for key, val of @upload_params()
      form_data.append key, val

    form_data.append "file", @data.file

    xhr = new XMLHttpRequest
    xhr.upload.addEventListener "progress", (e) =>
      if e.lengthComputable
        @progress? e.loaded, e.total

    xhr.upload.addEventListener "error", (e) =>
      sendEvent "upload", "xhr error", @kind

    xhr.upload.addEventListener "abort", (e) =>
      sendEvent "upload", "xhr abort", @kind

    xhr.addEventListener "load", (e) =>
      @uploading = false
      @on_update?()

      if xhr.status != 200 && xhr.status != 204
        return @set_error "server failed to accept upload"

      try
        res = $.parseJSON(xhr.responseText)
        if res.errors
          return @set_error "#{res.errors.join ", "}"

      if @save_url
        $.when(@save_url).done (url, params) =>
          $.post url, with_csrf(params), (res) =>
            if res.errors
              return @set_error "#{res.errors.join ", "}"

            @save_upload res
      else
        @save_upload res

    xhr.open "POST", action
    xhr.send form_data

  progress: (loaded, total) =>
    @progress_percent = loaded/total * 100
    @on_update?()

  save_upload: (res) =>
    @success = true
    @on_update?()

  set_error: (msg) =>
    @current_error = msg
    @on_update?()


# manages the lifecycle of uploads
export class UploadManager
  constructor: (@opts={}) ->

  pick_files: (on_upload) =>
    @input.remove() if @input
    @input = $("<input type='file' multiple />").hide().insertAfter document.body

    if @opts.accept
      @input.attr "accept", @opts.accept

    @input.on "change", =>
      for file in @input[0].files
        @push_file file, on_upload

    @input.click()

  push_file: (file, on_upload) =>
    max_size = @opts.max_size
    if max_size? and file.size > max_size
      alert "#{file.name} is greater than max size of #{format_bytes max_size}"
      return

    @prepare_and_start_upload file, on_upload

  prepare_and_start_upload: (file, callback) ->
    throw "missing prepare url" unless @opts.prepare_url

    data = with_csrf {
      "upload[filename]": file.name
      "upload[size]": file.size
    }

    find_image_demensions = get_image_dimensions file

    $.post @opts.prepare_url, data, (res) =>
      if res.errors
        return alert res.errors.join ", "

      upload = new Upload {
        filename: file.name
        size: file.size
        type: file.type
        file: file
        id: res.id
      }

      upload.set_upload_params res.post_params

      upload.set_save_url find_image_demensions.then (width, height, thumbnail) =>
        params = {
          width, height
        }

        if thumbnail
          params["thumbnail[data_url]"] = thumbnail.data_url
          params["thumbnail[width]"] = thumbnail.width
          params["thumbnail[height]"] = thumbnail.height

        $.when res.save_url, params

      upload.start_upload res.url

      callback? upload, file

