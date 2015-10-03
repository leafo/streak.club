import underscore from require "lapis.util"

class Page extends require "widgets.base"
  @widget_name: => underscore(@__name or "unknown") .. "_page"

  @css_classes: =>
    return "page_widget" if @ == Page
    Page.__parent.css_classes @

  inner_content: =>
    div class: "base_widget", ->
      @column_content!

  column_content: =>

