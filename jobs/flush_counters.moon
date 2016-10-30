
print "starting counter flush"
local start

delay = 60

run = (premature) ->
  return if premature

  BrowsingFlow = require "community.flows.browsing"
  if counter = BrowsingFlow({})\view_counter!
    counter\sync!
    import run_after_dispatch from require "lapis.nginx.context"
    run_after_dispatch! -- manually release resources since we are in new context

  start!

start = ->
  unless ngx.timer.at delay, run
    print "Failed to create timer"

start!
