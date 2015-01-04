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
    trim_filter upload_params, { "type", "filename", "size" }

    assert_valid upload_params, {
      {"type", one_of: Uploads.types}
      {"filename", exists: true, max_length: 1028}
      {"size", is_integer: true}
    }

    upload = Uploads\create {
      user_id: @current_user.id
      type: upload_params.type
      size: upload_params.size
      filename: upload_params.filename
    }

    json: {
      url: signed_url @url_for("receive_upload", id: upload.id)
    }

  [receive_upload: "/uploads/receive/:id"]: require_login capture_errors_json =>
    assert_valid @params, {
      {"id", is_integer: true}
    }

    @upload = assert_error Uploads\find(@params.id), "invalid upload"
    assert_error @upload\allowed_to_edit(@current_user), "not allowed to edit"
    assert_error not @upload.ready, "upload already uploaded"

    json: @params

