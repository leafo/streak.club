
lapis = require "lapis"
db = require "lapis.db"

import assert_valid from require "lapis.validate"
import
  respond_to
  capture_errors
  assert_error
  capture_errors_json
  from require "lapis.application"

import trim_filter from require "lapis.util"

class SearchApplication extends lapis.Application
  [search: "/search"]: =>
    trim_filter @

    unless @params.q
      return redirect_to: @url_for "index"

    @noindex = true

    @query = @params.q
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
