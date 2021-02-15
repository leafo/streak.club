import types from require "tableshape"


-- from data object
get_user_id = types.partial {
  session: types.partial {
    user: types.partial {
      id: types.number\tag "user_id"
    }
  }
}

class AdminExceptions extends require "widgets.admin.page"
  @include "widgets.pagination_helpers"
  @include "widgets.table_helpers"

  @needs: {"exceptions"}

  column_content: =>
    div class: "page_header", ->
      h2 "Exceptions"

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
        {"ip", (e) ->
          if e.ip
            a href: @url_for("admin.users", nil, user_token: "ip.#{e.ip}"), e.ip
          else
            em class: "sub", "n/a"
        }
        {"user_id", (e) ->
          if res = get_user_id e.data
            code ->
              a href: @url_for("admin.user", id: res.user_id), res.user_id
          else
            em class: "sub", "n/a"
        }
        {"msg", type: "collapse_pre"}
        {"data", type: "json"}
        {"trace", type: "collapse_pre"}
      }

    @render_pager @pager
