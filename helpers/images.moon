config = require"lapis.config".get!

image_secret = config.image_secret or config.secret

import escape from require "socket.url"
import filter_update from require "helpers.model"

b64_for_url = do
  import encode_base64 from require "lapis.util.encoding"
  (str, len) ->
    str = encode_base64 str
    str = str\sub 1, len if len
    (str\gsub "[/+]", {
      "+": "%2B"
      "/": "%2F"
    })

unb64_from_url = do
  import decode_base64 from require "lapis.util.encoding"
  (str) ->
    str = str\gsub "%%2[BF]", {
      "%2B": "+"
      "%2F": "/"
    }

    decode_base64 str

image_signature = (chunk) ->
  b64_for_url ngx.hmac_sha1(image_secret, chunk), 6

thumb = do
  img_prefix = "/img"

  (subpath, size_str, extension) ->
    extension = subpath\match "%.([%w_]+)$" unless extension
    chunk = "#{b64_for_url subpath}/#{escape size_str}"
    "#{img_prefix}/#{chunk}/#{image_signature chunk}.#{extension}"

{ :thumb, :image_signature, :b64_for_url, :unb64_from_url }
