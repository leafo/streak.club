
import BrowseStreaksFlow from require "flows.browse_streaks"
StreakList = require "widgets.streak_list"

-- convert to url
flatten_filters = (filters) ->
  slugs = [val for k, val in pairs filters]
  table.sort slugs
  path = table.concat slugs, "/"
  path = "/" .. path if path != ""
  path

class Streaks extends require "widgets.page"
  @needs: {"facets"}

  column_content: =>
    div class: "page_header", ->
      h2 "Streaks"

    div class: "page_tabs", ->
      @filter_tab "category", nil, "All categories"
      @filter_tab "category", "visual_art"
      @filter_tab "category", "interactive"
      @filter_tab "category", "music"
      @filter_tab "category", "video"
      @filter_tab "category", "writing"
      @filter_tab "category", "other"

    div class: "page_tabs", ->
      @filter_tab "state", nil, "All states"
      @filter_tab "state", "active"
      @filter_tab "state", "upcoming"
      @filter_tab "state", "completed"

    if next @streaks
      widget StreakList
    else
      p class: "empty_message", "There don't appear to be any streaks here"

  filter_tab: (kind, val, label_override) =>
    all_filters = BrowseStreaksFlow.filters

    base_url = @url_for "streaks"

    filters = {k,v for k,v in pairs @filters}
    filters[kind] = val
    for k,v in pairs filters
      slug = all_filters[k][v]
      slug = v if slug == true
      filters[k] = slug

    filters_suffix = flatten_filters filters
    url = "#{base_url}#{filters_suffix}"

    classes = "tab"
    if @filters[kind] == val
      classes ..=  " active"

    a {
      href: url
      class: classes
      label_override or BrowseStreaksFlow.filter_names[kind][val]
    }

