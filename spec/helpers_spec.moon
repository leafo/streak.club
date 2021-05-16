describe "helpers", ->
  it "formats dates", ->
    date = require "date"
    import format_date from require "helpers.format"
    now = date true
    ago = date(now)\adddays -1
    future = date(now)\adddays 1

    assert.same "1 day ago", format_date ago
    assert.same "1 day from now", format_date future

