
import Uploads from require "models"

class AdminGenerateThumbnail extends require "widgets.admin.page"
  @es_module: [[
    import $ from "main/jquery"
    import {create_video_thumbnail_from_url} from "main/upload"

    let el = $(widget_selector)

    create_video_thumbnail_from_url(widget_params.download_url).then((data_url, width, height) => {
      el.find("img.preview").attr("src", data_url)
      el.find("[name=data_url]").val(data_url)
      el.find("[name=width]").val(width)
      el.find("[name=height]").val(height)
    })
  ]]

  js_init: =>
    super {
      download_url: @url_for @upload, 60*60*24
    }

  column_content: =>
    form class: "form", method: "POST", ->
      @csrf_input!

      p ->
        a href: @url_for("admin.uploads", nil, id: @upload.id), "Upload #{@upload.id}"
        text " | "
        download_url = @url_for @upload, 60*60*24
        a href: download_url, "Direct download link"
      
      div class: "admin_columns input_row", ->
        if thumb = @upload\get_upload_thumbnail!
          fieldset ->
            legend "Existing"
            img src: thumb.data_url, width: thumb.width, height: thumb.height

        fieldset ->
          legend "Generated"
          img class: "preview"

      div class: "input_row", ->
        textarea name: "data_url", readonly: true, placeholder: "Loading..."

      fieldset ->
        legend "Size"

        input type: "number", name: "width", readonly: true, required: true
        text " x "
        input type: "number", name: "height", readonly: true, required: true

      div class: "button_row", ->
        button class: "button", "Save thumbnail"





