
P = R.package "EditSubmission"

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
    [
      input {
        key: "selectize_wrapper"
        type: "text"
        placeholder: @props.placeholder
        value: @state.tags.join ","
        ref: (@input) =>
      }

      input {
        key: "value_input"
        type: "hidden"
        name: @props.name
        value: @state.tags.join ","
      }
    ]

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
    [
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
    ]

}

P "Uploader", {
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
    @dispatch "upload", {
      "delete": (pos) =>
        @state.uploads.splice(pos, 1)
        @forceUpdate()

      "move_up": (pos) =>
        uploads = @state.uploads

        old = uploads[pos - 1]
        uploads[pos - 1] = uploads[pos]
        uploads[pos] = old

        @forceUpdate()

      "move_down": (pos) =>
        uploads = @state.uploads

        old = uploads[pos + 1]
        uploads[pos + 1] = uploads[pos]
        uploads[pos] = old

        @forceUpdate()
    }

  render: ->
    div className: "upload_component", children: [
      P.UploadList { uploads: @state.uploads }
      button {
        className: "new_upload_btn button"
        onClick: @handle_upload
        type: "button"
      }, "Add file(s)"
    ]
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
      div className: "upload_tools", children: [
        unless @props.first
          a { href: "# ", onClick: @handle_move_up, className: "move_up_btn" }, "Move up"

        unless @props.last
          a { href: "#", onClick: @handle_move_down, className: "move_down_btn" }, "Move Down"

        a { href: "#", className: "delete_btn", onClick: @handle_delete }, "Delete"
      ]

    upload_status = if msg = @props.upload.current_error
      div className: "upload_error", msg
    else if @props.upload.success
      div className: "upload_success", "Success"
    else if @props.upload.uploading
      progress = @props.upload.progress_percent || 0
      div className: "upload_progress",
        div className: "upload_progress_inner", style: { width: "#{progress}%" }

    div className: "file_upload", children: [
      input type: "hidden", name: "upload[#{@props.upload.data.id}][position]", value: "#{@props.position}"
      upload_tools
      div children: [
        span className: "filename", @props.upload.data.filename
        " "
        span className: "file_size", "(#{S.format_bytes @props.upload.data.size})"
        upload_status
      ]
    ]
}

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
          alert "#{file.name} is greater than max size of #{S.format_bytes max_size}"
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

      upload = new S.Upload {
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


