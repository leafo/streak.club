
class Upload
  upload_template: S.lazy_template @, "file_upload"
  constructor: (@data, @manager) ->
    @el = $ @upload_template data
    @el.data "upload", @
    @el.data "upload_id", @data.id

    @progress_bar = @el.find ".upload_progress"
    @progress_bar_inner = @progress_bar.find ".upload_progress_inner"

  upload_params: => {}

  start_upload: (action) ->
    throw "missing file" unless @data.file

    @el.addClass "uploading"

    form_data = new FormData()
    for key, val of @upload_params()
      form_data.append key, val

    form_data.append "file", @data.file

    xhr = new XMLHttpRequest
    xhr.upload.addEventListener "progress", (e) =>
      if e.lengthComputable
        @progress? e.loaded, e.total

    xhr.upload.addEventListener "error", (e) =>
      S.event "upload", "xhr error", @kind

    xhr.upload.addEventListener "abort", (e) =>
      S.event "upload", "xhr abort", @kind

    xhr.addEventListener "load", (e) =>
      @el.removeClass "uploading"

      if xhr.status != 200
        return @set_error "server failed to accept upload"

      res = $.parseJSON(xhr.responseText)
      if res.errors
        return @set_error "#{res.errors.join ", "}"

      @save_upload res

    xhr.open "POST", action
    xhr.send form_data

  progress: (loaded, total) =>
    p = loaded/total * 100
    @progress_bar_inner.css "width", "#{p}%"

  save_upload: (res) =>
    @el.addClass("has_success")
      .trigger "s:upload_complete", [@]

  set_error: (msg) =>
    @el.addClass("has_error").find(".upload_error").text msg

class UploaderManager
  constructor: (@button_el, @view, @opts) ->
    input = null
    @upload_list = @view.el.find ".file_upload_list"

    @button_el.on "click", (e) =>
      e.preventDefault()

      input.remove() if input
      input = $("<input type='file' multiple />").hide().insertAfter(@button_el)
      if accept = @button_el.data "accept"
        input.attr "accept", accept

      max_size = @button_el.data "max_size"
      input.on "change", =>
        for file in input[0].files
          if max_size? and file.size > max_size
            alert "#{file.name} is greater than max size of #{_.str.formatBytes max_size}"
            continue

          console.log "start file", file
          @prepare_upload {
            "upload[type]": "image"
            "upload[filename]": file.name
            "upload[size]": file.size
          }, (res) =>
            upload = new Upload {
              filename: file.name
              size: file.size
              type: file.type
              file: file
              id: res.id
              position: @next_upload_position()
            }
            @upload_list.append upload.el
            upload.start_upload res.url

      input.insertAfter @button_el
      input.click()

  prepare_upload: (data, callback) ->
    prepare_url = @button_el.data "url"
    $.post prepare_url, S.with_csrf(data), (res) =>
      if res.errors
        return alert res.errors.join ", "

      callback? res

  next_upload_position: ->
    @upload_list.find(".file_upload").length

class S.EditSubmission
  constructor: (el) ->
    @el = $ el
    new UploaderManager @el.find(".new_upload_btn"), @

