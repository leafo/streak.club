import request, request_as from require "spec.helpers"
import use_test_server from require "lapis.spec"

factory = require "spec.factory"

describe "users", ->
  use_test_server!

  import Users, Followings, Submissions, Streaks,
    StreakSubmissions, StreakUsers, SubmissionTags from require "spec.models"

  it "should create a user", ->
    factory.Users!

  it "loads forgot password", ->
    status, res = request_as nil, "/user/forgot-password"
    assert.same 200, status

  it "should load index logged in", ->
    current_user = factory.Users!
    request_as current_user, "/"

  it "loads user settings logged in", ->
    current_user = factory.Users!
    request_as current_user, "/user/settings"

  it "loads feed logged in", ->
    current_user = factory.Users!
    request_as current_user, "/feed"

  it "should load login", ->
    status, res = request "/login"
    assert.same 200, status

  it "should view user profile", ->
    user = factory.Users!
    status, res = request "/u/#{user.slug}"
    assert.same 200, status

  it "views user profile when user has submissions and joined streak", ->
    user = factory.Users!
    streak = factory.Streaks!
    factory.StreakUsers streak_id: streak.id, user_id: user.id
    factory.StreakSubmissions streak_id: streak.id, user_id: user.id

    status, res = request "/u/#{user.slug}"
    assert.same 200, status

  it "views user profile tags", ->
    user = factory.Users!
    status, res = request "/u/#{user.slug}/tags"
    assert.same 200, status

  it "should register user", ->
    status, res, headers = request_as nil, "/register", {
      post: {
        username: "leafo"
        password: "hello"
        password_repeat: "hello"
        email: "leafo@example.com"
        accept_terms: "yes"
      }
    }

    assert.same 1, #Users\select!
    assert.same 302, status
    assert.same "http://localhost/", headers.location

  it "should log in user", ->
    user = factory.Users password: "hello world"

    status, res, headers = request_as nil, "/login", {
      post: {
        username: user.username\upper!
        password: "hello world"
      }
    }

    assert.same 302, status
    assert.same "http://localhost/", headers.location

  describe "with streaks", ->
    local current_user

    before_each ->
      current_user = factory.Users!

    active_streaks = ->
      current_user\find_participating_streaks(state: "active", per_page: 100)\get_page!

    all_streaks = ->
      current_user\find_participating_streaks(per_page: 100)\get_page!

    it "in no streak", ->
      factory.Streaks state: "during"

      assert.same 0, #active_streaks!
      assert.same 0, #all_streaks!

    describe "in streaks of all states", ->
      before_each ->
        factory.Streaks state: "during" -- not in this one
        for state in *{"during", "before_start", "after_end"}
          streak = factory.Streaks state: state
          factory.StreakUsers streak_id: streak.id, user_id: current_user.id

      it "get active streaks and all streaks", ->
        assert.same 1, #active_streaks!
        assert.same 3, #all_streaks!

      it "should get submittable streaks", ->
         assert.same 1, #current_user\find_submittable_streaks!

      it "should find participating streaks", ->
        assert.same 3, #current_user\find_participating_streaks!\get_page!
        assert.same 1, #current_user\find_participating_streaks(state: "active")\get_page!
        assert.same 1, #current_user\find_participating_streaks(state: "upcoming")\get_page!
        assert.same 1, #current_user\find_participating_streaks(state: "completed")\get_page!

        assert.same 3, #current_user\find_participating_streaks(publish_status: "published")\get_page!
        assert.same 0, #current_user\find_participating_streaks(publish_status: "draft")\get_page!

        assert.same 1, #current_user\find_participating_streaks(publish_status: "published", state: "active")\get_page!

    it "should get draft streak", ->
      streak = factory.Streaks state: "during", publish_status: "draft"
      factory.StreakUsers streak_id: streak.id, user_id: current_user.id

      assert.same 1, #active_streaks!
      assert.same 1, #all_streaks!
      assert.same 0, #current_user\find_participating_streaks({
        publish_status: "published"
        state: "active"
      })\get_page!

    it "should get hidden streak", ->
      streak = factory.Streaks state: "during", publish_status: "hidden"
      factory.StreakUsers streak_id: streak.id, user_id: current_user.id

      assert.same 1, #active_streaks!
      assert.same 1, #all_streaks!
      assert.same 0, #current_user\find_participating_streaks({
        publish_status: "published"
        state: "active"
      })\get_page!

    it "should get submittable streaks with submission", ->
      streaks = for i=1,3
        streak = factory.Streaks state: "during"
        factory.StreakUsers streak_id: streak.id, user_id: current_user.id
        streak

      factory.StreakSubmissions {
        streak_id: streaks[1].id
        user_id: current_user.id
      }
      assert.same 2, #current_user\find_submittable_streaks!

  describe "with submissions", ->
    local current_user

    before_each ->
      current_user = factory.Users!

      for i=1,3
        factory.Submissions user_id: current_user.id

    it "should view user profile", ->
      status, res = request "/u/#{current_user.slug}"
      assert.same 200, status

    it "should view user profile json", ->
      status, res = request "/u/#{current_user.slug}?format=json", {
        expect: "json"
      }
      assert.same 200, status

  describe "submission_tags", ->
    local current_user

    before_each ->
      current_user = factory.Users!

    it "should detect if user has no tags", ->
      SubmissionTags\create submission_id: -1, user_id: -1, slug: "hello-world"
      assert.falsy current_user\has_tags!

    it "should detect if user has no tags", ->
      SubmissionTags\create submission_id: -1, user_id: current_user.id, slug: "hello-world"
      assert.truthy current_user\has_tags!


  describe "settings", ->
    local current_user

    before_each ->
      current_user = factory.Users!

    it "loads settings page", ->
      status = request_as current_user, "/user/settings"
      assert.same 200, status

    it "updates account settings", ->
      status, res = request_as current_user, "/user/settings", {
        post: {
          "user[display_name]": "hello world"
          "user_profile[bio]": "<p>this is my profile!</p>"
        }
      }

      current_user\refresh!
      assert.same "hello world", current_user.display_name
      profile = current_user\get_user_profile!
      assert.same "<p>this is my profile!</p>", profile.bio

