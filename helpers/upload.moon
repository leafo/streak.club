import yield_error from require "lapis.application"

config = require"lapis.config".get!
storage = require "secret.storage"
storage_bucket = config.storage_bucket

assert_file_uploaded = (obj) ->
  -- somtimes GS doesn't think the file is ready try, attempt to wait for it
  local status, head
  key = obj\bucket_key!
  for i=1,60
    status, head = storage\head_file storage_bucket, key
    break if status == 200
    ngx.sleep 0.5

  unless status == 200
    yield_error "uploaded file does not exist in storage (#{key}: #{status})"

  head

{ :assert_file_uploaded }
