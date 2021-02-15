
class AdminExceptions extends require "widgets.admin.page"
  @include "widgets.pagination_helpers"
  @include "widgets.table_helpers"

  @needs: {"exceptions"}

  column_content: =>
    @render_pager @pager

    for exception in *@exceptions
      @field_table exception, {
        {"path", (e) ->
          if e.method
            pre class: "http_method", "#{e.method} #{e.path}"
          else
            em class: "sub", "n/a"
        }
        "id"
        "created_at"
        {"msg", format: "collapse_pre"}
        {"data", format: "json"}
        {"trace", format: "collapse_pre"}
      }

    @render_pager @pager
