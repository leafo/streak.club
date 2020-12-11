
class ImageViewer extends require "widgets.page"
  js_init: =>
    @react_render "ImageViewer.Client", {
      server_url: @build_url @url_for("image_viewer_ws"), {
        scheme: "ws"
      }


      user: @current_user  and {
        id: @current_user.id
        name: @current_user\name_for_display!
      }
    }

