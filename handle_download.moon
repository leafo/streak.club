
import validate_signed_url from require "helpers.url"

params = ngx.req.get_uri_args!

is_valid = validate_signed_url {
  req: {
    parsed_url: {
      path: ngx.var.uri
    }
  }
  params: params
}

unless is_valid
  return ngx.exit ngx.HTTP_FORBIDDEN

if ngx.now! > tonumber params.expires
  return ngx.exit ngx.HTTP_GONE

import Uploads from require "models"

upload = if upload_id = ngx.var.uri\match "/download/.-(%d+)"
  Uploads\find upload_id

filename = if upload
  upload.filename
else
  ngx.var.uri\match"([^/]*)$"


filename = filename\gsub '"', "\\%1"

ngx.header.content_disposition = 'attachment; filename="' .. filename ..'"'
ngx.header.content_transfer_encoding = 'binary'
