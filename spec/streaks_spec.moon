import request, request_as from require "spec.helpers"
import use_test_server from require "lapis.spec"

date = require "date"
factory = require "spec.factory"

describe "streaks", ->
  use_test_server!

  import Streaks, Users, Submissions, StreakUsers, StreakSubmissions from require "spec.models"

  describe "with user", ->
    local current_user
    before_each ->
      current_user = factory.Users!

    streak_params = (override={}) ->
      p = {
        "streak[title]": "Streak world"
        "streak[short_description]": "This is my streak"
        "streak[description]": "Streak description here"
        "streak[hour_offset]": "0"
        "streak[start_date]": "2015-1-1"
        "streak[end_date]": "2015-2-1"
        "streak[publish_status]": "published"
        "streak[rate]": "daily"
        "streak[category]": "other"
        "streak[late_submit_type]": "public"
        "streak[membership_type]": "public"
        "streak[community_type]": "discussion"
        "timezone": "America/Los_Angeles"
      }

      for k,v in pairs override
        p[k] = v

      p

    it "should create streak", ->
      status, res = request_as current_user, "/streaks/new", {
        post: streak_params!
        expect: "json"
      }

      assert.same 200, status
      assert.falsy res.errors
      assert.truthy res.url

      assert.same 1, #Streaks\select!

      current_user\refresh!
      assert.same 1, current_user.streaks_count
      assert.same 0, current_user.hidden_streaks_count


    it "should create a hidden streak", ->
      status, res = request_as current_user, "/streaks/new", {
        post: streak_params {
          "streak[publish_status]": "hidden"
        }
        expect: "json"
      }

      assert.same 200, status
      assert.falsy res.errors

      current_user\refresh!
      assert.same 1, current_user.streaks_count
      assert.same 1, current_user.hidden_streaks_count

    it "should edit streak", ->
      streak = factory.Streaks user_id: current_user.id

      status, res = request_as current_user, "/streak/#{streak.id}/edit", {
        post: streak_params!
        expect: "json"
      }

      assert.same 200, status
      assert.falsy res.errors
      assert.truthy res.url

    it "should edit streak from public to hidden", ->
      streak = factory.Streaks user_id: current_user.id
      current_user\recount!

      status, res = request_as current_user, "/streak/#{streak.id}/edit", {
        post: streak_params {
          "streak[publish_status]": "hidden"
        }
        expect: "json"
      }

      assert.same 200, status
      assert.falsy res.errors
      assert.truthy res.url

      current_user\refresh!

      assert.same 1, current_user.streaks_count
      assert.same 1, current_user.hidden_streaks_count

    it "should not let stranger edit streak", ->
      streak = factory.Streaks user_id: current_user.id
      other_user = factory.Users!

      status, res = request_as other_user, "/streak/#{streak.id}/edit", {
        post: { }
      }

      assert.same 404, status

    it "should join streak", ->
      streak = factory.Streaks!
      status, res = request_as current_user, "/s/#{streak.id}/#{streak\slug!}", {
        post: {
          action: "join_streak"
        }
      }

      assert.same 302, status
      streak_user = assert unpack(StreakUsers\select!), "missing streak user"
      assert.same current_user.id, streak_user.user_id
      assert.same streak.id, streak_user.streak_id
      assert.same false, streak_user.pending

    it "should join streak members only streak with pending", ->
      streak = factory.Streaks membership_type: "members_only"
      status, res = request_as current_user, "/s/#{streak.id}/#{streak\slug!}", {
        post: {
          action: "join_streak"
        }
      }

      assert.same 302, status
      streak_user = assert unpack(StreakUsers\select!), "missing streak user"
      assert.same current_user.id, streak_user.user_id
      assert.same streak.id, streak_user.streak_id
      assert.same true, streak_user.pending


  describe "with fixed streak PST", ->
    local streak, user
    before_each ->
      user = factory.Users!
      streak = factory.Streaks {
        user_id: user.id
        start_date: "2015-3-1"
        end_date: "2015-4-5"
        hour_offset: -8
      }

    streak_url = (streak) ->
      "/s/#{streak.id}/#{streak\slug!}"

    it "should view streak", ->
      status = request streak_url(streak)
      assert.same 200, status

    it "should view streak participants", ->
      status = request streak_url(streak) .. "/participants"
      assert.same 200, status

    it "should view streak stats", ->
      status = request streak_url(streak) .. "/stats"
      assert.same 200, status

    it "should view streak top submissions", ->
      status = request streak_url(streak) .. "/top-submissions"
      assert.same 200, status

    it "should view streak top streaks", ->
      status = request streak_url(streak) .. "/top-streaks"
      assert.same 200, status

    it "should view streak json page", ->
      status, res = request streak_url(streak) .. "?format=json", {
        expect: "json"
      }
      assert.same 200, status

    it "should view streak as owner", ->
      status = request_as user, streak_url(streak)
      assert.same 200, status

    it "should view first streak unit day", ->
      status = request "/streak/#{streak.id}/unit/2015-03-01"
      assert.same 200, status

    it "should view last streak unit day", ->
      status = request "/streak/#{streak.id}/unit/2015-04-05"
      assert.same 200, status

    it "should view unit day with user id", ->
      status = request "/streak/#{streak.id}/unit/2015-04-05?user_id=123"
      assert.same 200, status

    describe "with submissions", ->
      before_each ->
        for i=1,2
          factory.StreakSubmissions {
            streak_id: streak.id
            submit_time: "2015-3-#{i} 09:00:00"
          }

      it "should view streak", ->
        status = request streak_url(streak)
        assert.same 200, status

      it "should view streak participants", ->
        status = request streak_url(streak) .. "/participants"
        assert.same 200, status

      it "should view streak json page", ->
        status, res = request streak_url(streak) .. "?format=json", {
          expect: "json"
        }
        assert.same 200, status

      it "should view streak json page 2", ->
        status, res = request streak_url(streak) .. "?format=json&page=2", {
          expect: "json"
        }
        assert.same 200, status

      it "should view unit with submissions", ->
        status = request "/streak/#{streak.id}/unit/2015-03-01"
        assert.same 200, status

      it "should lift user to top of submission", ->
        for i=1,3
          factory.StreakSubmissions {
            streak_id: streak.id
            submit_time: "2015-3-1 09:00:00"
          }

        submit = factory.Submissions {
          title: "I am lifted"
        }

        last = factory.StreakSubmissions {
          submission_id: submit.id
          user_id: submit.user_id

          streak_id: streak.id
          submit_time: "2015-3-1 09:00:00"
        }

        status = request "/streak/#{streak.id}/unit/2015-03-01", {
          get: {
            user_id: last.user_id
          }
        }
        assert.same 200, status

      it "should lift user to top of submission when there are a lot", ->
        for i=1,30
          factory.StreakSubmissions {
            streak_id: streak.id
            submit_time: "2015-3-1 09:00:00"
          }

        submit = factory.Submissions {
          title: "I am lifted"
        }

        last = factory.StreakSubmissions {
          submission_id: submit.id
          user_id: submit.user_id

          streak_id: streak.id
          submit_time: "2015-3-1 09:00:00"
        }

        status = request "/streak/#{streak.id}/unit/2015-03-01", {
          get: {
            user_id: last.user_id
          }
        }
        assert.same 200, status
