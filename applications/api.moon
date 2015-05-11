
lapis = require "lapis"

import assert_valid from require "lapis.validate"
import capture_errors_json, assert_error, respond_to from require "lapis.application"
import trim_filter from require "lapis.util"
import ApiKeys, Users from require "models"

import find_streak from require "helpers.app"

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
  fields = {
    "id", "start_date", "end_date", "hour_offset", "title", "short_description"
  }

  (s) ->
    import Streaks from require "models"
    out = {f, s[f] for f in *fields}
    out.host = format_user s\get_user!

    out.publish_status = Streaks.publish_statuses\to_name s.publish_status
    out.rate = Streaks.rates\to_name s.rate
    out.category = Streaks.categories\to_name s.category

    out

class StreakApi extends lapis.Application
  "/api/1/login": capture_errors_json =>
    trim_filter @params
    assert_valid @params, {
      { "source", one_of: ApiKeys.sources }
      { "username", exists: true }
      { "password", exists: true }
    }

    user = assert_error Users\login @params.username, @params.password
    key = ApiKeys\find_or_create user.id, @params.source

    json: { :key }


  "/api/1/register": capture_errors_json =>
    trim_filter @params
    assert_valid @params, {
      { "source", one_of: ApiKeys.sources }
      { "username", exists: true, min_length: 2, max_length: 25 }
      { "password", exists: true, min_length: 2 }
      { "password_repeat", equals: @params.password }
      { "email", exists: true, min_length: 3 }
    }

    assert_error @params.email\match(".@."), "invalid email address"
    user = assert_error Users\create {
      username: @params.username
      email: @params.email
      password: @params.password
    }

    key = ApiKeys\find_or_create user.id, @params.source

    json: { :key }


  -- Streaks user is in
  "/api/1/my-streaks": api_request =>
    import Users, Streaks from require "models"

    prepare_results = (streaks) ->
      Users\include_in streaks, "user_id"
      streaks

    joined = @current_user\find_participating_streaks(:prepare_results)\get_page!
    hosted = @current_user\find_hosted_streaks(:prepare_results)\get_page!

    joined = Streaks\group_by_state joined
    hosted = Streaks\group_by_state hosted


    out = {}
    for {groups, kind} in *{{joined, "joined"}, {hosted, "hosted"}}
      out[kind] = {k, [format_streak s for s in *streaks] for k, streaks in pairs groups}

    json: out

  "/api/1/streaks": api_request =>
    import BrowseStreaksFlow from require "flows.browse_streaks"
    flow = BrowseStreaksFlow @
    flow\browse_by_filters {}

    json: {
      streaks: [format_streak streak for streak in *@streaks]
    }

  "/api/1/streak/:id/join": api_request respond_to {
    POST: =>
      find_streak @
      -- TODO: this notification stuff is copied
      streak_user = @streak\join @current_user
      if streak_user
        import Notifications from require "models"
        Notifications\notify_for @streak\get_user!, @streak, "join", @current_user

      json: { :streak_user, joined: streak_user and true or false }
  }

  "/api/1/streak/:id/leave": api_request respond_to {
    POST: =>
      find_streak @
      left = @streak\leave @current_user
      json: { left: not not left }
  }

  "/api/1/submit": api_request =>
