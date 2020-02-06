
import Uploads from require "models"

class AdminUploads extends require "widgets.admin.page"
  @include "widgets.pagination_helpers"
  @include "widgets.table_helpers"

  @needs: {"uploads", "pager"}

  column_content: =>
    h2 "Uploads"

    @render_pager @pager
    @column_table @uploads, {
      "id"
      "created_at"
      {"user", (upload) ->
        user = upload\get_user!
        a href: @url_for(user), user\name_for_display!
      }
      {"object", (upload) ->
        if object = upload\get_object!
          a href: @url_for(object),
            "#{object.__class.__name} #{object.id}"
      }
      "ready"
      "deleted"
      {"type", Uploads.types}
      "extension"
      "width"
      "height"
      {"size", type: "filesize"}
      "downloads_count"
      {"storage_type", Uploads.storage_types}
    }
    @render_pager @pager

