
(options) ->
  busted = require "busted"
  handler = require('busted.outputHandlers.base') options

  local spec_name

  busted.subscribe { "suite", "start" }, (context) ->
    -- print "start suite"

  busted.subscribe { "test", "start" }, (context) ->
    -- print "start test"

  busted.subscribe { "test", "end" }, ->
    -- print "end test"
    spec_name = nil

  busted.subscribe { "suite", "end" }, (context) ->
    -- print "end suite"

  busted.subscribe { "lapis", "screenshot" }, (url, opts) ->
    print url

  handler
