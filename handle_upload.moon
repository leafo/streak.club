
FILE_PARAM = "file"

import to_json from require "lapis.util"

import Uploads from require "models"
import validate_signed_url from require "helpers.url"
import parse_content_disposition from require "lapis.util"
import shell_escape, exec from require "lapis.util"

logging = require "lapis.logging"
resty_upload = require "resty.upload"

handle_upload = ->
  is_valid = validate_signed_url {
    req: {
      parsed_url: {
        path: ngx.var.uri
      }
    }
    params: ngx.req.get_uri_args!
  }

  return nil, "invalid signature" unless is_valid
  upload = Uploads\find ngx.var.upload_id
  return nil, "already uploaded" if upload.ready

  full_path = Uploads.root_path .. "/" ..  upload\path!

  dir = full_path\match "^(.+)/[^/]+$"
  exec "mkdir -p '#{shell_escape dir}'" if dir

  input, err = resty_upload\new 8192
  return nil, err unless input
  input\set_timeout 1000 -- 1 sec

  current = {}

  file = assert io.open full_path, "w"
  success, err = pcall ->
    while true
      t, res, err = input\read!
      switch t
        when "body"
          if current.name == FILE_PARAM
            assert(file, "file already closed")\write res
        when "header"
          name, value = unpack res
          if name == "Content-Disposition"
            if params = parse_content_disposition value
              for tuple in *params
                current[tuple[1]] = tuple[2]
          else
            current[name\lower!] = value
        when "part_end"
          if current.name == FILE_PARAM
            file\close!
            file = nil

          current = {}
        when "eof"
          break
        else
          return nil, err or "failed to read upload"

  if file
    file\close!
    return nil, "failed to upload file: #{err}"

  ngx.header["Content-Type"] = "application/json"
  ngx.print to_json { success: true }
  upload\update ready: true

  logging.request {
    req: {
      cmd_mth: ngx.var.request_method
      cmd_url: ngx.var.uri
    }
    res: { status: 200 }
  }

  true

success, err = handle_upload!

unless success
  ngx.header["Content-Type"] = "application/json"
  ngx.print to_json { errors: {err} }

