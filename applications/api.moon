
lapis = require "lapis"

import assert_valid from require "lapis.validate"
import capture_errors_json from require "lapis.application"

import ApiKeys from require "models"

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
      key = ApiKeys\generate user.id, @params.source

    json: { :key }

