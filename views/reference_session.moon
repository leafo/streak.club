
class ReferenceSession extends require "widgets.page"
  responsive: true

  @needs: {"reference_session"}

  @es_module: [[
    import {ReferenceSession} from "main/react/reference_session"
    import {createRoot} from 'react-dom/client';
    createRoot(document.querySelector(widget_selector)).render(ReferenceSession(widget_params))
  ]]

  js_init: =>
    super {
      uploader_opts: {
        prepare_url: @url_for "prepare_upload"
        accept: "image/png,image/jpeg,image/gif"
      }
    }


  inner_content: =>

