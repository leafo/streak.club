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
import signed_url from require "helpers.url"

import Uploads from require "models"

class UploadsApplication extends lapis.Application
  [prepare_upload: "/uploads/prepare"]: require_login capture_errors_json =>
    assert_csrf @

    assert_valid @params, {
      {"upload", type: "table"}
    }

    upload_params = @params.upload
    trim_filter upload_params, { "filename", "size" }

    assert_valid upload_params, {
      {"filename", exists: true, max_length: 1028}
      {"size", is_integer: true}
    }

    upload = assert_error Uploads\create {
      user_id: @current_user.id
      size: upload_params.size
      filename: upload_params.filename
    }

    json: {
      id: upload.id
      url: signed_url @url_for("receive_upload", id: upload.id)
    }

  [receive_upload: "/uploads/receive/:id"]: =>
    error "placeholder for routing, handled in nginx"

