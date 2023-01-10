
lapis = require "lapis"
db = require "lapis.db"

types = require "lapis.validate.types"
import with_params from require "lapis.validate"

import capture_errors from require "lapis.application"

class SearchApplication extends lapis.Application
  [search: "/search"]: capture_errors{
    on_error: =>
      redirect_to: @url_for "index"

    with_params {
      {"q", types.limited_text 128}
    }, (params) =>
      @noindex = true

      @query = params.q
      @results = {}

      import Users, Streaks, Followings from require "models"

      fields = db.interpolate_query "*, similarity(username, ?)", @query
      @results.users = Users\select [[
        where username % ?
        order by similarity desc
        limit 10
      ]], @query, :fields

      fields = db.interpolate_query "*, similarity(title, ?)", @query
      @results.streaks = Streaks\select [[
        where title % ? and not deleted and publish_status = ?
        order by similarity desc
        limit 10
      ]], @query, Streaks.publish_statuses.published, :fields

      for key in *{"streaks", "users"}
        @results[key] = nil unless next @results[key]

      if streaks = @results.streaks
        Users\include_in streaks, "user_id"

      if users = @results.users
        Followings\load_for_users users, @current_user

      render: true
  }
