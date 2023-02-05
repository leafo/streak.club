
import Uploads from require "models"

class AdminUploads extends require "widgets.admin.page"
  @include "widgets.pagination_helpers"
  @include "widgets.table_helpers"

  @needs: {"uploads", "pager"}

  page_name: "uploads"

  column_content: =>
    h2 "Uploads"

    @filter_form (field) ->
      field "id"
      field "user_id"
      field "submission_id"
      field "storage_type", Uploads.storage_types

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
      {"view", (upload) ->
        if upload\is_image! and not upload.deleted and upload.ready
          a href: @url_for(upload), "view"
      }
      {"download", (upload) -> }
      {"data", (upload) ->
        if upload.data and next upload.data
          import to_json from require "lapis.util"
          code style: "font-size: small", to_json upload.data
      }
    }
    @render_pager @pager

