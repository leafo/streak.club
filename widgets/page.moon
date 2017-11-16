import underscore from require "lapis.util"

class Page extends require "widgets.base"
  @widget_name: => underscore(@__name or "unknown") .. "_page"

  @css_classes: =>
    return "page_widget" if @ == Page
    Page.__parent.css_classes @

  inner_content: =>
    if @column_content
      div class: "inner_column", ->
        @column_content!
