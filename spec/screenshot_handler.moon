dir = "spec/screenshots"
import slugify from require "lapis.util"

import parse_query_string, encode_query_string from require "lapis.util"

get_file_name = (context) ->
  busted = require "busted"

  names = { context.name or context.descriptor }

  while true
    context = busted.parent context
    break unless context
    name = context.name or context.descriptor
    break if context.descriptor == "file"
    table.insert names, 1, name

  names = for name in *names
    slugify assert name\gsub("#%w*", "")\match("^%s*(.-)%s*$"), "no spec name"

  table.concat names, "."

screenshot_path = do
  counts = {}
  (spec_name) ->
    full_name = if counts[spec_name]
      counts[spec_name] += 1
      "#{spec_name}.#{counts[spec_name]}"
    else
      counts[spec_name] = 1
      spec_name

    "#{dir}/#{full_name}.png"

(options) ->
  busted = require "busted"
  handler = require("busted.outputHandlers.utfTerminal") options

  local spec_name

  busted.subscribe { "test", "start" }, (context) ->
    spec_name = get_file_name context

  busted.subscribe { "test", "end" }, ->
    spec_name = nil

  busted.subscribe { "lapis", "html" }, (html, opts) ->
    fname = screenshot_path spec_name
    f = io.popen "wkhtmltoimage -q - '#{fname}'", "w"
    f\write html
    f\close!

  busted.subscribe { "lapis", "screenshot" }, (url, opts) ->
    assert spec_name, "no spec name set"

    import get_current_server from require "lapis.spec.server"
    server = get_current_server!

    if opts.get
      _, url_query = url\match "^(.-)%?(.*)$"
      get_params = url_query and parse_query_string(url_query) or {}
      for k,v in pairs opts.get
        get_params[k] = v

      url = url\gsub("(%?.*)$", "") .. "?" .. encode_query_string get_params

    host, path = url\match "^https?://([^/]*)(.*)$"
    unless host
      host = "127.0.0.1"
      path = url

    full_url = "http://#{host}:#{server.app_port}#{path}"
    headers = for k,v in pairs opts.headers or {}
      "'--header=#{k}:#{v}'"

    headers = table.concat headers

    cmd = "CutyCapt #{headers} '--min-width=1024' '--url=#{full_url}' '--out=#{screenshot_path(spec_name)}'"
    assert os.execute cmd

  handler
