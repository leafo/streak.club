
config = require("lapis.config").get!
import assert_error from require "lapis.application"
import parse_query_string from require "lapis.util"

local signed_url, validate_signed_url, assert_signed_url
do
  import encode_query_string from require "lapis.util"
  import encode_base64, decode_base64, hmac_sha1 from require "lapis.util.encoding"

  split_url = (url) ->
    path, query = url\match "https?://[^/]*([^?]*)%??(.*)"

    unless path
      path, query = url\match "([^?]*)%??(.*)"

    unless path
      path = url
      query = {}

    if type(query) == "string"
      query = parse_query_string query

    path, query

  calc_signature = (path, params, salt="", friendly=false) ->
    params_flat = ["#{p[1]}::#{p[2]}" for p in *params]
    table.sort params_flat
    params_flat = table.concat params_flat, ","

    -- error "using default secret" if config.secret == "please-change-me"
    sig = encode_base64 hmac_sha1 config.secret .. salt, "#{path} #{params_flat}"
    sig = sig\gsub "[^%w]", "" if friendly
    sig

  signed_url = (url, opts={}) ->
    assert type(opts) == "table", "signature call needs to be upgraded"
    param_name = opts.param_name or "sig"

    path, params = split_url url
    path ..= " #{opts.extra_data}" if opts.extra_data

    signature = calc_signature path, params, tostring(opts.salt or ""), opts.friendly
    sep = url\match"%?" and "&" or "?"
    url .. sep .. encode_query_string [param_name]: signature

  validate_signed_url = (r, opts={}) ->
    assert type(opts) == "table", "signature call needs to be upgraded"
    param_name = opts.param_name or "sig"

    path, params = split_url ngx.var.request_uri
    params = [p for p in *params when p[1] != param_name]
    path ..= " #{opts.extra_data}" if opts.extra_data

    signature = calc_signature path, params, tostring(opts.salt or ""), opts.friendly
    if signature == r.params[param_name]
      true
    else
      nil, "invalid signature"

  assert_signed_url = (...) ->
    assert_error validate_signed_url ...

{:signed_url, :validate_signed_url, :assert_signed_url}
