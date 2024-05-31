
class ReferenceSession extends require "widgets.page"
  responsive: true

  @needs: {"reference_session"}

  @es_module: [[
    import {ReferenceSession} from "main/react/reference_session"
    import {createRoot} from 'react-dom/client';
    createRoot(document.querySelector(widget_selector)).render(ReferenceSession(widget_params))
  ]]

  inner_content: =>

