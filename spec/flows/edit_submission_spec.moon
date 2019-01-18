import use_test_env from require "lapis.spec"
import in_request from require "spec.helpers.flow"

import types from require "tableshape"

factory = require "spec.factory"

describe "EditSubmissionFlow", ->
  use_test_env!

  import Users, Streaks, Submissions, StreakSubmissions from require "spec.models"

  local current_user

  before_each ->
    current_user = factory.Users!

  it "submits to daily streak", ->
    streak = factory.Streaks!
    streak\join current_user

    assert in_request {
      post: {
        ["submit_to[#{streak.id}]"]: "on"
        "submission[title]": "Hello world"
        "submission[user_rating]": "good"
      }
    }, =>
      @current_user = current_user
      @flow("edit_submission")\create_submission!

    submissions = Submissions\select!

    assert types.shape({
      types.shape {
        title: "Hello world"
        description: types.nil
        user_id: current_user.id
        published: true
      }, open: true
    }) submissions

    assert types.shape({
      types.shape {
        late_submit: false
        streak_id: streak.id
        submission_id: submissions[1].id
        user_id: current_user.id
      }, open: true
    }) StreakSubmissions\select!




