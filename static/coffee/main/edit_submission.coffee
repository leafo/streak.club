
class S.Upload
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
      S.event "upload", "xhr error", @kind

    xhr.upload.addEventListener "abort", (e) =>
      S.event "upload", "xhr abort", @kind

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
        $.post @save_url, S.with_csrf(), (res) =>
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

class S.EditSubmission
  constructor: (el, @opts) ->
    @el = $ el
    form = @el.find("form")
    form.remote_submit (res) =>
      if res.errors
        form.set_form_errors res.errors
        return

      if res.url
        window.location = res.url

    @setup_uploader()

  setup_uploader: =>
    container = @el.find ".file_uploader"

    uploader = R.EditSubmission.Uploader {
      uploads: @opts.uploads && (new S.Upload(u) for u in @opts.uploads)
      uploader_opts: @opts.uploader_opts
      widget: @
    }

    ReactDOM.render uploader, container[0]

