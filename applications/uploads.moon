lapis = require "lapis"

import with_params from require "lapis.validate"

types = require "lapis.validate.types"

import
  respond_to
  capture_errors
  yield_error
  assert_error
  capture_errors_json
  from require "lapis.application"

import not_found, require_login, with_csrf from require "helpers.app"

import Uploads from require "models"

find_upload = with_params {
  {"id", types.db_id}
}, (params) =>
  @upload = assert_error Uploads\find(params.id), "invalid upload"

sizestring = types.string\length(0,15) * types.pattern("^%d+$")

class UploadsApplication extends lapis.Application
  [prepare_upload: "/uploads/prepare"]: require_login capture_errors_json respond_to {
    POST: with_csrf with_params {
      {"upload", types.params_shape {
        {"filename", types.limited_text 256}
        {"size", sizestring}
      }}
    }, (params) =>
      upload = assert_error Uploads\create {
        user_id: @current_user.id
        size: params.upload.size
        filename: params.upload.filename
      }

      upload_url, params = upload\upload_url_and_params @

      json: {
        id: upload.id
        url: upload_url
        save_url: upload\save_url @
        post_params: params
      }
  }

  [save_upload: "/uploads/save/:id"]: require_login capture_errors_json respond_to {
    POST: with_csrf with_params {
      {"id", types.db_id}
      {"width", types.empty + sizestring / tonumber}
      {"height", types.empty + sizestring / tonumber}

      {"thumbnail", types.empty + types.params_shape {
        {"width", sizestring / tonumber}
        {"height", sizestring / tonumber}
        {"data_url", types.limited_text(1024*5) * types.pattern "^data:image/jpeg;base64"}
      }}
    }, (params) =>
      upload = Uploads\find params.id
      assert_error upload\allowed_to_edit(@current_user), "invalid upload"
      import assert_file_uploaded from require "helpers.upload"
      assert_file_uploaded upload

      upload\update {
        ready: true
        width: params.width
        height: params.height
      }

      if params.thumbnail
        import UploadThumbnails from require "models"
        UploadThumbnails\create {
          upload_id: upload.id
          width: params.thumbnail.width
          height: params.thumbnail.height
          data_url: params.thumbnail.data_url
       }

      json: { success: true }
  }

  [prepare_download: "/uploads/download/:id"]: capture_errors {
    on_error: => not_found
    respond_to {
      GET: => yield_error "invalid method"

      POST: with_csrf =>
        find_upload @

        assert_error @upload\allowed_to_download(@current_user), "invalid upload"

        @upload\increment!
        redirect_to: @url_for @upload
    }
  }

  [prepare_play_video: "/uploads/play-video/:id"]: capture_errors {
    on_error: => not_found

    respond_to {
      GET: => yield_error "invalid method"

      POST: with_csrf =>
        find_upload @

        assert_error @upload\allowed_to_download(@current_user), "invalid upload"
        assert_error @upload\is_video!, "upload must be video"

        @upload\increment_video!

        json: {
          url: @url_for @upload, 60*60
          expires: os.time! + 60*60
        }
    }
  }

  [prepare_play_audio: "/uploads/play-audio/:id"]: capture_errors {
    on_error: => not_found
    respond_to {
      GET: => yield_error "invalid method"

      POST: with_csrf =>
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

