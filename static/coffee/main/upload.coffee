
import $ from "main/jquery"
import {event as sendEvent, with_csrf} from "main/util"

import {format_bytes} from "main/util"

# attempt to turn some rejected value into the standardized {errors: []} format
# for use in the form error and errors lightbox
export wrap_errors = (d) ->
  d.then null, (res) =>
    obj = if typeof res == 'string'
      { errors: [res] }
    else if Array.isArray(res) && res.every (item) => typeof item == 'string'
      { errors: res }
    else if "readyState" of res and "status" of res
      # this is an xhr object (either the real one or the jquery wrapped one)
      Object.assign {
        errors: [
          "Server error (#{res.status})"
          "Please contact support if the error persists"
        ]
      }, res.responseJSON
    else
      res

    $.Deferred().reject obj

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




export xhr_upload = (file, opts) ->
  $.Deferred (d) =>
    form_data = new FormData()

    for key, val of opts.post_params
      form_data.append key, val

    form_data.append "file", file

    xhr = new XMLHttpRequest

    xhr.upload.addEventListener "progress", (e) =>
      if e.lengthComputable
        d.notify "progress", e.loaded, e.total

    xhr.upload.addEventListener "error", (e) =>
      d.reject "xhr error"

    xhr.upload.addEventListener "abort", (e) =>
      d.reject "xhr aborted"

    xhr.addEventListener "readystatechange", (e) =>
      return unless xhr.readyState == 4

      # we assume we're uploading to GCS so we parse xml
      if Math.floor(xhr.status / 100) == 2
        d.resolve()
      else
        message = "Failed upload."
        if xhr.responseXML
          try
            message = xhr.responseXML.querySelector("Error Message").innerHTML
          catch e
            # ignore
        else
          message = xhr.responseText

        d.reject message

    xhr.open "POST", opts.action
    xhr.send form_data


export class Upload
  constructor: (@data) ->

  start_upload: (upload_url, save_url) ->
    throw "missing file" unless @data.file

    @uploading = true
    @on_update?()

    d = wrap_errors $.when(upload_url).then (action, upload_params) =>
      xhr_upload(@data.file, {
        action
        post_params: upload_params
      })
        .progress (status, loaded, total) =>
          if status == "progress"
            @progress? loaded, total
        .then (upload_result) =>
          @uploading = false
          @on_update?()

          if save_url
            $.when(save_url).then (url, params) =>
              $.post(url, with_csrf(params)).then (res) =>
                if res.errors
                  return $.Deferred().reject res

                res
          else
            upload_result


    d.fail (error) =>
      @uploading = false
      @on_update?()
      @set_error error

    d.then (res) =>
      @save_upload res
      res

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

  # pick a single file, returning promise of the upload
  pick_file: =>
    @input.remove() if @input

    @input = $("<input type='file' />").hide().insertAfter document.body

    if @opts.accept
      @input.attr "accept", @opts.accept

    d = $.Deferred()

    @input.on "change", =>
      if file = @input[0].files[0]
        d.resolve @upload_file file, on_upload

    @input.click()

    d

  pick_files: (on_upload) =>
    @input.remove() if @input
    @input = $("<input type='file' multiple />").hide().insertAfter document.body

    if @opts.accept
      @input.attr "accept", @opts.accept

    @input.on "change", =>
      for file in @input[0].files
        @upload_file file, on_upload

    @input.click()

  # returns a deferred representing the upload
  # on_upload: called when the Upload object is created and started
  upload_file: (file, on_upload) ->
    throw "missing prepare url" unless @opts.prepare_url

    data = with_csrf {
      "upload[filename]": file.name
      "upload[size]": file.size
    }

    d = get_image_dimensions(file).then (width, height, thumbnail) =>
      max_size = @opts.max_size
      if max_size? and file.size > max_size
        return $.Deferred().reject "#{file.name} is greater than max size of #{format_bytes max_size}"

      $.post(@opts.prepare_url, data).then (res) =>
        if res.errors
          return $.Deferred().reject res

        upload = new Upload {
          filename: file.name
          size: file.size
          type: file.type
          file: file
          id: res.id
        }

        save_params = {
          width, height
        }

        if thumbnail
          save_params["thumbnail[data_url]"] = thumbnail.data_url
          save_params["thumbnail[width]"] = thumbnail.width
          save_params["thumbnail[height]"] = thumbnail.height

        upload_action = $.when res.url, res.post_params
        save_action = $.when res.save_url, save_params

        upload.start_upload upload_action, save_action
        on_upload upload, d

    d


