import
  load_test_server
  close_test_server
  from require "lapis.spec.server"

import truncate_tables from require "lapis.spec.db"

import
  Streaks
  Users
  Submissions
  StreakUsers
  StreakSubmissions
  SubmissionComments from require "models"

factory = require "spec.factory"
import request, request_as from require "spec.helpers"

describe "submission_comments", ->
  local current_user

  setup ->
    load_test_server!

  teardown ->
    close_test_server!

  before_each ->
    truncate_tables Streaks,
      Users,
      Submissions,
      StreakUsers,
      StreakSubmissions,
      SubmissionComments

    current_user = factory.Users!

  it "should create a comment", ->
    submission  = factory.Submissions!
    status, res = request_as current_user, "/submission/#{submission.id}/comment", {
      post: {
        ["comment[body]"]: "Hello world"
      }
      expect: "json"
    }
      
    assert.truthy res.success
    assert.same 1, res.comments_count
    comments = SubmissionComments\select!
    assert.same 1, #comments
    comment = unpack comments

    assert.same comment.user_id, current_user.id
    assert.same comment.submission_id, submission.id
    assert.same comment.body, "Hello world"
    assert.same comment.deleted, false


