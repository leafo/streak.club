import use_test_env from require "lapis.spec"

describe "models.DailyUploadDownloads", ->
  use_test_env!
  import DailyUploadDownloads from require "spec.models"

  it "should increment downloads", ->
    assert.same "create", DailyUploadDownloads\increment 123
    assert.same "update", DailyUploadDownloads\increment 123

    downloads = DailyUploadDownloads\select!
    assert.same 1, #downloads
    assert.same 2, downloads[1].count


