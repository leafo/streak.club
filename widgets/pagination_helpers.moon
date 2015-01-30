
import encode_query_string from require "lapis.util"

class PaginationHelpers
  render_pager: (pager=@pager, current_page=@page) =>
    num_pages = pager\num_pages!
    return if num_pages < 2
    default_params = {k,v for k,v in pairs @GET}

    page_url = (p) ->
      default_params.page = if p == 1 then nil else p
      "?" .. encode_query_string default_params

    div class: "pager", ->
      if current_page > 1
        a href: page_url(current_page - 1), class: "prev_page button", "Prev"

      if current_page < num_pages
        a href: page_url(current_page + 1), class: "next_page button", "Next"

      span class: "pager_label", ->
        text "Page #{current_page} of "
        a href: page_url(num_pages), "#{num_pages}"


