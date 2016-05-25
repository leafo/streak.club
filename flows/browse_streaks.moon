db = require "lapis.db"

import Flow from require "lapis.flow"
import assert_page from require "helpers.app"

-- convert to url
flatten_filters = (filters) ->
  slugs = [val for k, val in pairs filters]
  table.sort slugs
  path = table.concat slugs, "/"
  path = "/" .. path if path != ""
  path

flip_filters = (filters) ->
  out = {}

  for kind, values in pairs filters
    for value, slug in pairs values
      slug = value unless type(slug) == "string"
      out[slug] = { [kind]: value }

  out

class BrowseStreaksFlow extends Flow
  -- maps enum -> slug
  @filters: {
    category: {
      visual_art: "visual-arts"
      interactive: true
      music: "music-and-audio"
      video: true
      writing: true
      other: true
    }

    state: {
      active: "in-progress"
      upcoming: true
      completed: true
    }
  }

  -- maps slug chunk to tuple
  @filters_flipped: flip_filters @filters

  -- enum -> name
  @filter_names: {
    category: {
      visual_art: "Visual arts"
      music: "Music & audio"
      video: "Video"
      writing: "Writing"
      interactive: "Interactive"
      other: "Other"
    }

    state: {
      active: "In progress"
      upcoming: "Upcoming"
      completed: "Completed"
    }
  }


  @slug_name: (kind, value) =>
    slug = @filters[kind][value]
    slug = value if slug == true
    name = @filter_names[kind][value] or value

    slug, name

  expose_assigns: true

  filtered_url: (filters) =>
    base_url = @url_for("streaks")

    filters = {k,v for k,v in pairs filters}
    for k,v in pairs filters
      slug = @@filters[k][v]
      slug = v if slug == true
      filters[k] = slug

    filters_suffix = flatten_filters filters
    "#{base_url}#{filters_suffix}"

  filtered_title: (filters) =>
    text = "Streaks"
    if c = filters.category
      text = "#{@@filter_names.category[c]} #{text}"

    if s = filters.state
      text = "#{@@filter_names.state[s]} #{text}"

    "Browse #{text}"

  parse_filters: =>
    return {} unless @params.splat

    has_invalid = false
    out = {}
    for slug in @params.splat\gmatch "([%w-]+)"
      tuple = @@filters_flipped[slug]
      unless tuple
        has_invalid = true
        continue

      for k,v in pairs tuple
        -- something else already set ij
        has_invalid = true if out[k]
        out[k] = v

    out, has_invalid

  browse_by_filters: (filters={}) =>
    import Streaks, Users from require "models"

    assert_page @

    clause = {
      publish_status: Streaks.publish_statuses.published
    }

    if c = filters.category
      clause.category = Streaks.categories\for_db c

    time_clause = if s = filters.state
      Streaks\_time_clause s

    @pager = Streaks\paginated "
      where #{db.encode_clause clause}
      #{time_clause and "and " .. time_clause or ""}
      order by users_count desc
    ", {
      per_page: 100
      prepare_results: (streaks) ->
        Users\include_in streaks, "user_id"
        streaks
    }

    @streaks = @pager\get_page @page
    @streaks

