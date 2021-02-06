import use_test_env from require "lapis.spec"

describe "models.DailyUploadDownloads", ->
  use_test_env!
  import DailyUploadDownloads from require "spec.models"

  it "should increment downloads", ->
    assert.same true, DailyUploadDownloads\increment 123
    assert.same true, DailyUploadDownloads\increment 123

    assert.same true, DailyUploadDownloads\increment 9, 3

    assert.same true, DailyUploadDownloads\increment 1, 2
    assert.same true, DailyUploadDownloads\increment 1, 2

    now = DailyUploadDownloads\date!

    downloads = DailyUploadDownloads\select "order by upload_id asc"
    assert.same {
      {
        upload_id: 1
        count: 4
        date: now
      }
      {
        upload_id: 9
        count: 3
        date: now
      }
      {
        upload_id: 123
        count: 2
        date: now
      }
    }, downloads


