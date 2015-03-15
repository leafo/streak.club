
class Search extends require "widgets.base"
  inner_content: =>
    pre require("moon").dump @results

