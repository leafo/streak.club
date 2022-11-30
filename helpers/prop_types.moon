-- this augments the built in set of types from tableshape with new types for
-- use with the prop_types widget class parameter

import types from require "tableshape"
moon_types = require "tableshape.moonscript"

import render_prop from require "lapis.eswidget.prop_types"

date = require "date"

date_mt = getmetatable date(true)
date = (types.string + types.metatable_is(types.literal(date_mt)))\describe "date timestamp"

setmetatable {
  :render_prop
  :date
  instance_of: moon_types.instance_of
}, __index: types
