
import $ from "main/jquery"
import {event as sendEvent, with_csrf} from "main/util"

export create_video_thumbnail_from_url = (url) ->
  v = document.createElement('video')
  v.crossOrigin = "anonymous"
  v.src = url

  $.Deferred (d) ->
    thumbnail_size = 48

    v.addEventListener "seeked", ->
      {data_url, width, height} = create_video_thumbnail v
      d.resolve data_url, width, height

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
