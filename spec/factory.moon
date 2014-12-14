
models = require "models"
db = require "lapis.db"

import Model from require "lapis.db.model"
import slugify from require "lapis.util"

next_counter = do
  counters = setmetatable {}, __index: => 1
  (name) ->
    with counters[name]
      counters[name] += 1

next_email = ->
  "me-#{next_counter "email"}@example.com"

Users = (opts={}) ->
  opts.username or= "user-#{next_counter "username"}"
  opts.email or= next_email!
  opts.password or= "my-password"
  assert models.Users\create opts

{ :Users }
