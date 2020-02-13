
P = R.package "EditSubmission"

# NOTE: all files pass through here, so we should return nothing for non-images
get_image_dimensions = (file) ->
  $.Deferred (d) ->
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

P "TagInput", {
  getInitialState: ->
    {
      tags: _.toArray @props.tags
    }

  componentDidMount: ->
    suggested_tags = _.toArray @props.suggested_tags
    tags_input = $ @input
    default_tags = _.toArray @props.tags

    tags_input.selectize {
      maxItems: 10
      delimiter: ','
      plugins: ['remove_button']
      persist: false
      placeholder: tags_input.attr("placeholder")
      valueField: 'slug'
      labelField: 'slug'
      searchField: ['slug']
      closeAfterSelect: true
      options: suggested_tags.concat(default_tags).map (x) -> { slug: x }
      create: (tag) -> { slug: tag }
      onChange: =>
        tags = @input.selectize.items || []
        @setState tags: tags
        @props.on_change_tags? tags
    }

  render: ->
    fragment {},
      input {
        key: "selectize_wrapper"
        type: "text"
        placeholder: @props.placeholder
        defaultValue: @state.tags.join ","
        ref: (@input) =>
      }

      input {
        key: "value_input"
        type: "hidden"
        name: @props.name
        value: @state.tags.join ","
      }
}

P "Editor", {
  getInitialState: ->
    initial_html = @props.value

    initial_markdown = if initial_html
      turndownService = new TurndownService {
        hr: "---"
      }

      turndownService.turndown initial_html

    {
      html: initial_html or ""
      markdown: initial_markdown or ""
    }

  componentDidMount: ->
    if @props.autofocus
      @focus()

  focus: ->
    @textarea.focus()

  set_markdown: (md) ->
    @setState {
      markdown: md
      html: @compile_markdown md
    }

  compile_markdown: (md) ->
    @parser ||= new commonmark.Parser()
    @writer ||= new commonmark.HtmlRenderer {
      smart: true
      softbreak: "<br />"
    }

    document = @parser.parse(md)
    @writer.render(document)

  render: ->
    fragment {},
      unless @props.show_format_help == false
        div className: "markdown_label",
          img {
            height: 16
            width: 26
            src: "/static/images/markdown-mark-solid.svg"
            alt: "Markdown Enabled"
          }
          "Format with Markdown"

      textarea {
        value: @state.markdown
        placeholder: @props.placeholder
        ref: (textarea) => @textarea = textarea
        required: @props.required
        onKeyDown: @props.on_key_down
        onChange: (e) =>
          @setState {
            markdown: e.target.value
            html: @compile_markdown e.target.value
          }

          @props.on_change? e.target.value
      }

      input type: "hidden", name: @props.name, value: @state.html

}

P "Uploader", {
  getInitialState: ->
    {
      uploads: @props.uploads || []
      upload_manager: new UploaderManager @props.uploader_opts
    }

  push_upload: (upload) ->
    @state.uploads.push upload
    @forceUpdate()
    upload.on_update = => @forceUpdate()


  handle_upload: (e) ->
    e.preventDefault()
    @state.upload_manager.pick_files @push_upload

  componentDidMount: ->
    move = (item, dir) =>
      current_idx = null
      items = for other, idx in @state.uploads
        if other == item
          current_idx = idx
          continue

        other

      items.splice current_idx + dir, 0, item
      items


    @dispatch "upload", {
      "delete": (e, pos) =>
        @setState {
          uploads: (u for u, idx in @state.uploads when idx != pos)
        }

      "move_up": (e, pos) =>
        @setState {
          uploads: move @state.uploads[pos], -1
        }

      "move_down": (e, pos) =>
        @setState {
          uploads: move @state.uploads[pos], 1
        }
    }

  render: ->
    div {
      className: classNames "upload_component", {
        dragging: @state.dragging_over
      }

      onDragEnter: (e) =>
        @drag_counter ||= 0
        @drag_counter += 1

        if @drag_counter == 1
          @setState dragging_over: true

      onDragLeave: (e) =>
        @drag_counter ||= 0
        @drag_counter -= 1

        if @drag_counter == 0
          @setState dragging_over: false

      onDragOver: (e) =>
        e.stopPropagation()
        e.preventDefault()

      onDrop: (e) =>
        e.preventDefault()

        @drag_counter = 0
        @setState dragging_over: false

        for file in e.dataTransfer?.files
          @state.upload_manager.push_file file, @push_upload
    },
      P.UploadList { uploads: @state.uploads }

      if @state.dragging_over
        div className: "dragging_target" , "Drop to upload..."

      div className: "upload_actions",
        button {
          className: "new_upload_btn button"
          onClick: @handle_upload
          type: "button"
        }, "Add file(s)"

        unless S.is_mobile()
          p className: "upload_tip", "TIP: you can also drag and drop a file(s) here to upload"
}

P "UploadList", {
  render: ->
    div className: "file_upload_list", @render_uploads()

  render_uploads: ->
    @props.uploads.map (upload, idx) =>
      P.Upload {
        key: upload.data.id
        upload: upload
        position: idx
        first: idx == 0
        last: idx == @props.uploads.length - 1
      }
}

P "Upload", {
  container: ->
    $ ReactDOM.findDOMNode @

  handle_delete: (e) ->
    e.preventDefault()
    if confirm "Are you sure you want to remove this file?"
      @trigger "upload:delete", @props.position

  handle_move_up: (e) ->
    e.preventDefault()
    @trigger "upload:move_up", @props.position

  handle_move_down: (e) ->
    e.preventDefault()
    @trigger "upload:move_down", @props.position

  render: ->
    upload_tools = unless @props.upload.uploading
      div className: "upload_tools",
        unless @props.first
          button { type: "button", onClick: @handle_move_up, className: "move_up_btn" }, "Move up"

        unless @props.last
          button { type: "button", onClick: @handle_move_down, className: "move_down_btn" }, "Move Down"

        button { type: "button", className: "delete_btn", onClick: @handle_delete }, "Delete"

    upload_status = if msg = @props.upload.current_error
      div className: "upload_error", msg
    else if @props.upload.success
      div className: "upload_success", "Success"
    else if @props.upload.uploading
      progress = @props.upload.progress_percent || 0
      div className: "upload_progress",
        div className: "upload_progress_inner", style: { width: "#{progress}%" }

    div className: "file_upload",
      input type: "hidden", name: "upload[#{@props.upload.data.id}][position]", value: "#{@props.position}"
      upload_tools
      div {},
        span className: "filename", @props.upload.data.filename
        " "
        span className: "file_size", "(#{S.format_bytes @props.upload.data.size})"
        upload_status
}

class UploaderManager
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
      alert "#{file.name} is greater than max size of #{S.format_bytes max_size}"
      return

    @prepare_and_start_upload file, on_upload

  prepare_and_start_upload: (file, callback) ->
    throw "missing prepare url" unless @opts.prepare_url

    data = S.with_csrf {
      "upload[filename]": file.name
      "upload[size]": file.size
    }

    find_image_demensions = get_image_dimensions file

    $.post @opts.prepare_url, data, (res) =>
      if res.errors
        return alert res.errors.join ", "

      upload = new S.Upload {
        filename: file.name
        size: file.size
        type: file.type
        file: file
        id: res.id
      }

      upload.set_upload_params res.post_params

      upload.set_save_url find_image_demensions.then (width, height) =>
        $.when res.save_url, { width, height }

      upload.start_upload res.url

      callback? upload, file


