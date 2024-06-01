
import $ from "main/jquery"

import "main/react/edit_submission"

import {createRoot} from "react-dom/client"
import {Uploader} from "main/react/edit_submission"

export class EditSubmission
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
    createRoot(container[0]).render Uploader {
      uploads: @opts.uploads
      uploader_opts: @opts.uploader_opts
    }

