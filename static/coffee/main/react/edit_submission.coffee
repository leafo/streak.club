
import {R, fragment, classNames} from "./_react"

import * as React from 'react'
import * as ReactDOM from 'react-dom'
import {div, input, textarea, button, span, img, p, dialog, h2} from 'react-dom-factories'

import $ from "main/jquery"
import {with_markdown, is_mobile, format_bytes, with_csrf} from "main/util"
import {Upload} from "main/upload"

import {_} from "main/global_libs"

P = R.package "EditSubmission"

import {create_video_thumbnail} from "main/upload"

import {ArrowUpIcon, ArrowDownIcon} from "main/react/icons"

# NOTE: all files pass through here, so we should return nothing for non-images
# NOTE: this also generates thumbnail for video file
get_image_dimensions = (file) ->
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

export TagInput = P "TagInput", {
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

convert_to_markdown = (html) ->
  turndownService = new window.TurndownService { hr: "---" }
  turndownService.turndown html

export Editor = P "Editor", {
  getInitialState: ->
    initial_html = @props.value
    initial_markdown = null

    md_deferred = with_markdown()
    loading = md_deferred.state() == "pending"

    if loading
      md_deferred.then =>
        if initial_html
          @setState {
            markdown: convert_to_markdown initial_html
            loading: false
          }
        else
          @setState loading: false
    else
      # we can convert it right away with since it's already loaded
      if initial_html
        initial_markdown = convert_to_markdown initial_html

    {
      loading
      html: initial_html || ""
      markdown: initial_markdown || ""
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
    @parser ||= new window.commonmark.Parser()
    @writer ||= new window.commonmark.HtmlRenderer {
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
            className: "svg_icon"
            src: "/static/images/markdown-mark-solid.svg"
            alt: "Markdown Enabled"
          }
          "Format with Markdown"

      textarea {
        value: @state.markdown
        placeholder: if @state.loading then "Loading..." else @props.placeholder
        disabled: !!@state.loading
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

export PastedFileDialog = P "PastedFileDialog", {
  componentDidMount: ->
    @dialog_ref.current.addEventListener "close", (e) => @props.on_close?()
    @dialog_ref.current.showModal()

    @img_ref.current.src = URL.createObjectURL @props.file

  render: ->
    dialog {
      ref: @dialog_ref ||= React.createRef()
      className: "pasted_file_dialog lightbox"
    },
      h2 {}, "Upload pasted image?"
      img {
        className: "image_preview"
        ref: @img_ref ||= React.createRef()
      }

      p className: "image_size", "Image size: #{format_bytes @props.file.size}"

      div className: "button_column",
        button {
          className: "button"
          type: "button"
          onClick: =>
            @props.on_accept()
        }, "Upload"
        button {
          className: "button outline_button"
          type: "button"
          onClick: =>
            @dialog_ref.current.close()
        },
          "Cancel"
          span className: "keyboard_key", "ESC"
}



export Uploader = P "Uploader", {
  getInitialState: ->
    {
      uploads: @props.uploads || []
      upload_manager: new UploaderManager @props.uploader_opts
    }

  push_upload: (upload) ->
    @setState {
      uploads: @state.uploads.concat(upload)
    }

    # TODO: remove the use of forceUpdate
    upload.on_update = => @forceUpdate()

  handle_upload: (e) ->
    e.preventDefault()
    @state.upload_manager.pick_files @push_upload

  on_paste: (e) ->
    return if @state.loading

    clipboardData = e.clipboardData || window.clipboardData

    for item in clipboardData.items
      continue unless item.kind == "file"
      continue unless item.type == "image/png" || item.type == "image/jpeg"
      continue unless item.getAsFile?

      file = item.getAsFile()
      e.preventDefault()
      @setState {
        pasted_file: file
      }
      break

  componentDidMount: ->
    document.body.addEventListener "paste", @on_paste

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
    fragment {},
      @render_uploader()
      if @state.pasted_file
        @render_pasted_file()

  render_pasted_file: ->
    PastedFileDialog {
      file: @state.pasted_file

      on_accept: =>
        @state.upload_manager.push_file @state.pasted_file, @push_upload
        @setState {
          pasted_file: null
        }

      on_close: =>
        @setState {
          pasted_file: null
        }
    }

  render_uploader: ->
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

        unless is_mobile()
          p className: "upload_tip", "TIP: you can also drag and drop a file(s) here to upload"
}

export UploadList = P "UploadList", {
  render: ->
    div className: "file_upload_list", @render_uploads()

  render_uploads: ->
    @props.uploads.map (upload, idx) =>
      P.UploadRow {
        key: upload.data.id
        upload: upload
        position: idx
        first: idx == 0
        last: idx == @props.uploads.length - 1
      }
}

export UploadRow = P "UploadRow", {
  handle_delete: (e) ->
    e.preventDefault()
    if confirm "Are you sure you want to remove this file? This can not be undone."
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
        unless @props.first and @props.last
          button {
            disabled: @props.first
            type: "button"
            onClick: @handle_move_up
            className: "move_btn move_up_btn"
            title: "Move up"
          }, ArrowUpIcon(), span className: "screenreader_only", "Move up"

        unless @props.first and @props.last
          button {
            disabled: @props.last
            type: "button"
            onClick: @handle_move_down
            className: "move_btn move_down_btn"
            title: "Move down"
          }, ArrowDownIcon(), span className: "screenreader_only", "Move down"


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
        span className: "file_size", "(#{format_bytes @props.upload.data.size})"
        upload_status

      unless @props.upload.uploading
        div className: "upload_tools",
          button { type: "button", className: "delete_btn", onClick: @handle_delete }, "Delete"
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

