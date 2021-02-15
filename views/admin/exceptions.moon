import types from require "tableshape"

import ExceptionRequests, ExceptionTypes from require "lapis.exceptions.models"

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

  page_name: "exceptions"

  column_content: =>
    h2 "Exceptions"

    ul ->
      for status in *{
        "default"
        "resolved"
        "ignored"
      }
        li ->
          highlight = if @params.status == status then strong else text
          highlight ->
            a href: @url_for("admin.exceptions", nil, {:status}), ->
              code status

    @render_pager @pager

    unless next @exceptions
      p ->
        em "No results"

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
        {"exception_type", (e) ->
          if et = e\get_exception_type!
            code ->
              a href: @url_for("admin.exceptions", nil, exception_type_id: et.id), et.id

              text " (#{@number_format et.count})"

            text " "
            @render_table_value et, {"status", ExceptionTypes.statuses}
            text " "
            details style: "display: inline-block", ->
              summary "Update..."
              form method: "post", ->
                @csrf_input!
                input type: "hidden", name: "exception_request_id", value: e.id
                input type: "hidden", name: "action", value: "set_exception_status"

                unless et.status == ExceptionTypes.statuses.resolved
                  button {
                    name: "status"
                    value: "resolved"
                  }, "Resolve"
                  text " "

                unless et.status == ExceptionTypes.statuses.ignored
                  button {
                    name: "status"
                    value: "ignored"
                  }, "Ignore"
                  text " "

                unless et.status == ExceptionTypes.statuses.default
                  button {
                    name: "status"
                    value: "default"
                  }, "Default"
                  text " "
        }
      }

    @render_pager @pager
