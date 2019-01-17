lapis = require "lapis"

import assert_valid from require "lapis.validate"
import
  respond_to
  capture_errors
  yield_error
  assert_error
  capture_errors_json
  from require "lapis.application"

import not_found, require_login from require "helpers.app"

import assert_csrf from require "helpers.csrf"
import trim_filter from require "lapis.util"

import Uploads from require "models"

find_upload = =>
  assert_valid @params, {
    {"id", is_integer: true}
  }

  @upload = assert_error Uploads\find(@params.id), "invalid upload"

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

    upload_url, params = upload\upload_url_and_params @

    json: {
      id: upload.id
      url: upload_url
      save_url: upload\save_url @
      post_params: params
    }

  [save_upload: "/uploads/save/:id"]: require_login capture_errors_json =>
    assert_valid @params, {
      {"id", is_integer: true}
    }

    upload = Uploads\find @params.id
    assert_error upload\allowed_to_edit(@current_user), "invalid upload"
    import assert_file_uploaded from require "helpers.upload"
    assert_file_uploaded upload
    upload\update ready: true
    json: { success: true }

  [prepare_download: "/uploads/download/:id"]: capture_errors {
    on_error: => not_found
    respond_to {
      GET: => yield_error "invalid method"

      POST: =>
        assert_csrf @
        find_upload @

        assert_error @upload\allowed_to_download(@current_user), "invalid upload"

        @upload\increment!
        redirect_to: @url_for @upload
    }
  }

  [prepare_play_audio: "/uploads/play-audio/:id"]: capture_errors {
    on_error: => not_found
    respond_to {
      GET: => yield_error "invalid method"

      POST: =>
        assert_csrf @
        find_upload @

        assert_error @upload\allowed_to_download(@current_user), "invalid upload"
        assert_error @upload\is_audio!, "upload must be audio"

        @upload\increment_audio!

        json: {
          url: @url_for @upload, 60*60
          expires: os.time! + 60*60
        }
    }
  }

  [receive_upload: "/uploads/receive/:id"]: =>
    error "placeholder for routing, handled in nginx"

