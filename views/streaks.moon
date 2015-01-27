
StreakList = require "widgets.streak_list"

-- convert to url
flatten_filters = (filters) ->
  slugs = [val for k, val in pairs filters]
  table.sort slugs
  path = table.concat slugs, "/"
  path = "/" .. path if path != ""
  path

class Streaks extends require "widgets.base"
  @needs: {"facets"}

  inner_content: =>
    div class: "page_header", ->
      h2 "Streaks"

    div class: "page_tabs", ->
      @filter_tab "All types", "type", nil
      @filter_tab "Visual arts", "type", "visual_art", "visual-arts"
      @filter_tab "Interactive", "type", "interactive"
      @filter_tab "Music & audio", "type", "music", "music-and-audio"
      @filter_tab "Video", "type", "video"
      @filter_tab "Writing", "type", "writing"
      @filter_tab "Other", "type", "other"

    div class: "page_tabs", ->
      @filter_tab "All states", "state", nil
      @filter_tab "In progress", "state", "in-progress"
      @filter_tab "Upcoming", "state", "upcoming"
      @filter_tab "Completed", "state", "completed"

    if next @streaks
      widget StreakList
    else
      p class: "empty_message", "There don't appear to be any streaks here"


  filter_tab: (label, key, val, slug) =>
    base_url = @url_for "streaks"
    filters = {k,v for k,v in pairs @filters}
    filters[key] = slug or val

    filters_suffix = flatten_filters filters
    url = "#{base_url}#{filters_suffix}"

    classes = "tab"
    if @filters[key] == val
      classes ..=  " active"

    a href: url, class: classes, label

