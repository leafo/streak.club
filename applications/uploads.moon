lapis = require "lapis"

import assert_valid from require "lapis.validate"
import
  respond_to
  capture_errors
  assert_error
  capture_errors_json
  from require "lapis.application"

import not_found, require_login from require "helpers.app"

import assert_csrf from require "helpers.csrf"
import trim_filter from require "lapis.util"

import Uploads from require "models"

class UploadsApplication extends lapis.Application
  [prepare_upload: "/uploads/prepare"]: require_login capture_errors_json =>
    assert_csrf @

    assert_valid @params, {
      {"upload", type: "table"}
    }

    upload_params = @params.upload
    trim_filter upload_params, { "type" }

    assert_valid upload_params, {
      {"type", one_of: Uploads.types}
    }

    Uploads\create {
      user_id: @current_user.id
      type: upload_params.type
    }

