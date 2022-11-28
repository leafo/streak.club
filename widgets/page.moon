import underscore from require "lapis.util"

class Page extends require "widgets.base"
  @widget_class_name: =>
    if @ == Page
      "page_widget"
    else
      "#{@widget_name!}_page"

  inner_content: =>
    if @column_content
      div class: "inner_column", ->
        @column_content!
