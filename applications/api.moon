
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

  "/api/1/my-streaks": api_request =>
  "/api/1/streaks": api_request =>
  "/api/1/submit": api_request =>
