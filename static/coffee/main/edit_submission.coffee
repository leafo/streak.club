
class Upload
  upload_template: S.lazy_template @, "file_upload"
  constructor: (@data, @manager) ->
    @el = $ @upload_template data
    @el.data "upload", @

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
          upload = new Upload {
            filename: file.name
            size: file.size
            type: file.type
          }

          @upload_list.append upload.el

      input.insertAfter @button_el
      input.click()

  prepare_upload: (data, callback) =>
    prepare_url = @button_el.data "url"
    $.post prepare_url, S.with_csrf(), (res) =>
      if res.errors
        return alert res.errors.join ", "

      callback? res

class S.EditSubmission
  constructor: (el) ->
    @el = $ el
    new UploaderManager @el.find(".new_upload_btn"), @

