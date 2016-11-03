import use_test_server from require "lapis.spec"

import request, request_as from require "spec.helpers"

factory = require "spec.factory"

describe "applications.submission", ->
  use_test_server!

  local submission

  import Users, Submissions, SubmissionLikes, SubmissionTags from require "spec.models"

  before_each ->
    submission = factory.Submissions!

  it "renders delete submission page", ->
    status = request_as submission\get_user!, "/submission/#{submission.id}/delete"
    assert.same 200, status

  it "deletes the submission", ->
    status, _, headers = request_as submission\get_user!,
      "/submission/#{submission.id}/delete", {
        post: {
          action: "delete"
        }
      }

    assert.same 302, status
    assert.nil Submissions\find submission.id

