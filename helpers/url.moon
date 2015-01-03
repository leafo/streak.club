
config = require("lapis.config").get!
import assert_error from require "lapis.application"

local signed_url, validate_signed_url, assert_signed_url
do
  import encode_query_string from require "lapis.util"
  import encode_base64, decode_base64, hmac_sha1 from require "lapis.util.encoding"

  calc_signature = (path, salt="", friendly=false) ->
    -- error "using default secret" if config.secret == "please-change-me"
    sig = encode_base64 hmac_sha1 config.secret .. salt, path
    sig = sig\gsub "[^%w]", "" if friendly
    sig

  signed_url = (url, opts={}) ->
    assert type(opts) == "table", "signature call needs to be upgraded"
    param_name = opts.param_name or "sig"

    path = url\match("https?://[^/]*([^?]*)") or url
    path ..= tostring(opts.extra_data) if opts.extra_data

    signature = calc_signature path, tostring(opts.salt or ""), opts.friendly
    sep = url\match"%?" and "&" or "?"
    url .. sep .. encode_query_string [param_name]: signature

  validate_signed_url = (r, opts={}) ->
    assert type(opts) == "table", "signature call needs to be upgraded"
    param_name = opts.param_name or "sig"

    parsed = r.req.parsed_url
    path = parsed.original_path or parsed.path
    path ..= tostring(opts.extra_data) if opts.extra_data

    signature = calc_signature path, tostring(opts.salt or ""), opts.friendly
    if signature == r.params[param_name]
      true
    else
      nil, "invalid signature"

  assert_signed_url = (...) ->
    assert_error validate_signed_url ...

{:calc_signaturem, :signed_url, :validate_signed_url, :assert_signed_url}
