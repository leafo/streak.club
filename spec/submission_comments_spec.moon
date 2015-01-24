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
    submission = factory.Submissions!
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

  describe "with comment", ->
    local comment

    before_each ->
      comment = factory.SubmissionComments user_id: current_user.id

    it "should edit comment", ->
      status, res = request_as current_user, "/submission-comment/#{comment.id}/edit", {
        post: {
          "comment[body]": "my edit"
        }
        expect: "json"
      }

      assert.same 200, status
      assert.truthy res.success
      assert.truthy res.rendered

      comment\refresh!
      assert.same comment.body, "my edit"
      assert.truthy comment.edited_at

    it "should not let stranger edit comment", ->
      other_user = factory.Users!
      status, res = request_as other_user, "/submission-comment/#{comment.id}/edit", {
        post: {
          "comment[body]": "my edit"
        }
        expect: "json"
      }

      assert.same 200, status
      assert.truthy res.errors

      old_body = comment.body
      comment\refresh!
      assert.same comment.body, old_body

    it "should not let submission owner edit comment", ->
      owner = comment\get_submission!\get_user!
      status, res = request_as owner, "/submission-comment/#{comment.id}/edit", {
        post: {
          "comment[body]": "my edit"
        }
        expect: "json"
      }

      assert.same 200, status
      assert.truthy res.errors

    it "should delete comment", ->
      status, res = request_as current_user, "/submission-comment/#{comment.id}/delete", {
        post: { }
        expect: "json"
      }

      assert.same 200, status
      assert.truthy res.success

      comment\refresh!
      assert.truthy comment.deleted

      comment\get_submission!\refresh!
      assert.same comment.submission.comments_count, 0

    it "should not let stranger delete", ->
      other_user = factory.Users!
      status, res = request_as other_user, "/submission-comment/#{comment.id}/delete", {
        post: { }
        expect: "json"
      }

      assert.same 200, status
      assert.truthy res.errors

      comment\refresh!
      assert.falsy comment.deleted

    it "should let submission owner delete comment", ->
      owner = comment\get_submission!\get_user!
      status, res = request_as owner, "/submission-comment/#{comment.id}/delete", {
        post: { }
        expect: "json"
      }

      assert.same 200, status
      assert.truthy res.success
