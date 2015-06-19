import
  load_test_server
  close_test_server
  from require "lapis.spec.server"

import truncate_tables from require "lapis.spec.db"

import DailyUploadDownloads from require "models"

describe "downloads", ->
  setup ->
    load_test_server!

  teardown ->
    close_test_server!

  before_each ->
    truncate_tables DailyUploadDownloads

  it "should increment downloads", ->
    assert.same "create", DailyUploadDownloads\increment 123
    assert.same "update", DailyUploadDownloads\increment 123

    downloads = DailyUploadDownloads\select!
    assert.same 1, #downloads
    assert.same 2, downloads[1].count


