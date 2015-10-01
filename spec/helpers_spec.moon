import use_test_server from require "lapis.spec"
import request from require "lapis.spec.server"
import truncate_tables from require "lapis.spec.db"

import time_ago_in_words from require "lapis.util"

describe "helpers", ->
  use_test_server!

  before_each ->

  it "formats dates", ->
    date = require "date"
    import format_date from require "helpers.format"
    now = date true
    ago = date(now)\adddays -1
    future = date(now)\adddays 1

    assert.same "1 day ago", format_date ago
    assert.same "1 day from now", format_date future

