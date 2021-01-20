
URL = "https://www.google.com/recaptcha/api/siteverify"

import from_json from require "lapis.util"

config = require("lapis.config").get!
http = require "lapis.nginx.http"
ltn12 = require "ltn12"

import encode_query_string from require "lapis.util"

post_siteverify = (opts) ->
  params = {
    secret: assert config.recaptcha3.secret_key, "missing recaptcha_key secret"
  }

  if opts
    for k,v in pairs opts
      params[k] = v

  out = {}
  _, status = http.request {
    url: URL
    method: "POST"
    sink: ltn12.sink.table out
    source: ltn12.source.string encode_query_string params
    headers: {
      "Content-Type": "application/x-www-form-urlencoded"
    }
  }

  text = table.concat out
  from_json text

verify_recaptcha = (response, ip) ->
  res = post_siteverify {
    response: response
    remoteip: ip
  }

  res

{ :verify_recaptcha, :post_siteverify }

