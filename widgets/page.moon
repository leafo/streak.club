import underscore from require "lapis.util"

class Page extends require "widgets.base"
  @widget_name: =>
    if @ == Page
      return "page_widget"

    underscore(@__name or "unknown") .. "_page"

  inner_content: =>
    if @column_content
      div class: "inner_column", ->
        @column_content!
