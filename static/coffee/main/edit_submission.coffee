
@R = {}

{ div, span, a, p, ol, ul, li, strong, em, img,
  form, label, input, textarea, button,
  h1, h2, h3, h4, h5, h6 } = React.DOM

R.component = (name, data) ->
  data.displayName = "R.#{name}"
  cl = React.createClass(data)
  R[name] = React.createFactory(cl)
  R[name]._class = cl

R.component "Uploader", {
  getInitialState: ->
    {
      uploads: @props.uploads || []
      upload_manager: new UploaderManager @props.uploader_opts
    }

  handle_upload: (e) ->
    e.preventDefault()
    @state.upload_manager.pick_files (upload) =>
      @state.uploads.push upload
      @forceUpdate()
      upload.on_update = => @forceUpdate()

  componentDidMount: ->
    @props.widget.upload_component = @
    el = $(@getDOMNode())

    el.on "s:upload:delete", (e, pos) =>
      @state.uploads.splice(pos, 1)
      @forceUpdate()

    el.on "s:upload:move_up", (e, pos) =>
      uploads = @state.uploads
      console.log "up", pos

      old = uploads[pos - 1]
      uploads[pos - 1] = uploads[pos]
      uploads[pos] = old

      @forceUpdate()

    el.on "s:upload:move_down", (e, pos) =>
      console.log "down", pos

      uploads = @state.uploads

      old = uploads[pos + 1]
      uploads[pos + 1] = uploads[pos]
      uploads[pos] = old

      @forceUpdate()

  render: ->
    div className: "upload_component",
      (R.UploadList { uploads: @state.uploads }),
      (button className: "new_upload_btn button", onClick: @handle_upload, "Add file(s)")
}

R.component "UploadList", {
  render: ->
    div className: "file_upload_list", @render_uploads()

  render_uploads: ->
    for upload, idx in @props.uploads
      R.Upload {
        key: upload.data.id
        upload: upload
        position: idx
        first: idx == 0
        last: idx == @props.uploads.length - 1
      }
}

R.component "Upload", {
  handle_delete: (e) ->
    e.preventDefault()
    if confirm "Are you sure you want to remove this file?"
      $(@getDOMNode()).trigger "s:upload:delete", [@props.position]

  handle_move_up: (e) ->
    e.preventDefault()
    $(@getDOMNode()).trigger "s:upload:move_up", [@props.position]

  handle_move_down: (e) ->
    e.preventDefault()
    $(@getDOMNode()).trigger "s:upload:move_down", [@props.position]

  render: ->
    upload_tools = unless @props.upload.uploading
      (div className: "upload_tools",
        unless @props.first then (a { href: "# ", onClick: @handle_move_up, className: "move_up_btn" }, "Move up"),
        unless @props.last then (a { href: "#", onClick: @handle_move_down, className: "move_down_btn" }, "Move Down"),
        (a { href: "#", className: "delete_btn", onClick: @handle_delete }, "Delete"))

    upload_status = if msg = @props.upload.current_error
      div className: "upload_error", msg
    else if @props.upload.success
      div className: "upload_success", "Success"
    else if @props.upload.uploading
      progress = @props.upload.progress_percent || 0
      div className: "upload_progress", (div className: "upload_progress_inner", style: { width: "#{progress}%" })

    div className: "file_upload",
      (input type: "hidden", name: "upload[#{@props.upload.data.id}][position]", value: "#{@props.position}"),
      upload_tools,
      (div {},
        (span className: "filename", @props.upload.data.filename),
        " ",
        (span className: "file_size", "(#{_.str.formatBytes(@props.upload.data.size)})"),
        upload_status)
}

class Upload
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

class UploaderManager
  constructor: (@opts={}) ->

  pick_files: (on_upload) =>
    @input.remove() if @input
    @input = $("<input type='file' multiple />").hide().insertAfter document.body

    if @opts.accept
      @input.attr "accept", @opts.accept

    max_size = @opts.max_size
    @input.on "change", =>
      for file in @input[0].files
        if max_size? and file.size > max_size
          alert "#{file.name} is greater than max size of #{_.str.formatBytes max_size}"
          continue

        @prepare_and_start_upload file, on_upload

    @input.click()

  prepare_and_start_upload: (file, callback) ->
    throw "missing prepare url" unless @opts.prepare_url

    data = S.with_csrf {
      "upload[filename]": file.name
      "upload[size]": file.size
    }

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

      upload.set_save_url res.save_url
      upload.start_upload res.url

      callback? upload, file

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
    @setup_tags()

    S.redactor @el.find "textarea"

  setup_uploader: =>
    container = @el.find ".file_uploader"
    console.log @opts.uploads
    console.log @opts.uploader_opts

    React.render (R.Uploader {
      uploads: @opts.uploads && (new Upload(u) for u in @opts.uploads)
      uploader_opts: @opts.uploader_opts
      widget: @
    }), container[0]

  setup_tags: ->
    slug_input = @el.find ".tags_input"

    slug_input.tagit {
      availableTags: @opts.suggested_tags
      autocomplete: { delay: 0, minLength: 2 }
      allowSpaces: true
    }


