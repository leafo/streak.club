
BrowseStreaksFlow = require "flows.browse_streaks"
StreakList = require "widgets.streak_list"

class Streaks extends require "widgets.page"
  @needs: {"facets"}

  responsive: true

  column_content: =>
    div class: "page_header", ->
      h2 "Streaks"

    div class: "page_tabs", ->
      div class: "tabs_inner", ->
        @filter_tab "category", nil, "All categories"
        @filter_tab "category", "visual_art"
        @filter_tab "category", "interactive"
        @filter_tab "category", "music"
        @filter_tab "category", "video"
        @filter_tab "category", "writing"
        @filter_tab "category", "other"

    div class: "page_tabs", ->
      div class: "tabs_inner", ->
        @filter_tab "state", nil, "All states"
        @filter_tab "state", "active"
        @filter_tab "state", "upcoming"
        @filter_tab "state", "completed"

    if next @streaks
      widget StreakList
    else
      p class: "empty_message", "There don't appear to be any streaks here"

  filter_tab: (kind, val, label_override) =>
    filters = {k,v for k,v in pairs @filters}
    filters[kind] = val

    url = @flow("browse_streaks")\filtered_url filters

    classes = "tab"
    if @filters[kind] == val
      classes ..=  " active"

    a {
      href: url
      class: classes
      label_override or BrowseStreaksFlow.filter_names[kind][val]
    }

