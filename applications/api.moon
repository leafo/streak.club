
lapis = require "lapis"

import assert_valid from require "lapis.validate"
import capture_errors_json, assert_error from require "lapis.application"

import ApiKeys, Users from require "models"

api_request = (fn) ->
  capture_errors_json =>
    return fn @ if @params.key == "me" and @current_user
    @key = assert_error ApiKeys\find(key: @params.key), "invalid key"
    @current_user = Users\find id: @key.user_id
    fn @


format_user = (u) ->
  {
    id: u.id
    username: u.username
    display_name: u.display_name
  }

format_streak = do
  fields = {"id", "start_date", "end_date", "hour_offset"}
  (s) ->
    out = {f, s[f] for f in *fields}
    out.host = format_user s\get_user!
    out

class StreakApi extends lapis.Application
  "/api/1/login": capture_errors_json =>
    assert_valid @params, {
      { "source", one_of: {"ios"} }
      { "username", exists: true }
      { "password", exists: true }
    }

    user = assert_error Users\login @params.username, @params.password

    key = unpack ApiKeys\select [[
      where user_id = ? and source = ?
    ]], user.id, ApiKeys.sources\for_db @params.source

    unless key
      key = ApiKeys\create {
        user_id: user.id
        source: @params.source
      }

    json: { :key }

  -- Streaks user is in
  "/api/1/my-streaks": api_request =>
    import Users, Streaks from require "models"

    prepare_results = (streaks) ->
      Users\include_in streaks, "user_id"
      streaks

    active = @current_user\find_participating_streaks(state: "active", :prepare_results)\get_page!
    upcoming = @current_user\find_participating_streaks(state: "upcoming", :prepare_results)\get_page!
    completed = @current_user\find_participating_streaks(state: "completed", :prepare_results)\get_page!

    json: {
      active: [format_streak s for s in *active]
      upcoming: [format_streak s for s in *upcoming]
      completed: [format_streak s for s in *completed]
    }


  "/api/1/streaks": api_request =>
  "/api/1/submit": api_request =>
