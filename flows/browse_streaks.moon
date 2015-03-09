db = require "lapis.db"

import Flow from require "lapis.flow"

import assert_page from require "helpers.app"

class BrowseStreaksFlow extends Flow
  expose_assigns: true

  browse_by_filters: (filters={}) =>
    import Streaks, Users from require "models"

    assert_page @

    clause = {
      publish_status: Streaks.publish_statuses.published
    }

    if t = filters.type
      clause.category = Streaks.categories\for_db t

    time_clause = if s = filters.state
      s = "active" if s == "in-progress"
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


{:BrowseStreaksFlow}
