import use_test_env from require "lapis.spec"

import truncate_tables from require "lapis.spec.db"

factory = require "spec.factory"

describe "models.spam_scans", ->
  use_test_env!

  import Streaks, Users, Submissions, SpamScans from require "spec.models"

  import Categories, WordClassifications from require "lapis.bayes.models"

  before_each ->
    truncate_tables Categories, WordClassifications

  it "creates spam scan for user", ->
    user = factory.Users {
      username: "dad"
      display_name: "Spam User"
      email: "spammer@example.com"
    }

    scan = SpamScans\refresh_for_user user

    table.sort scan.text_tokens
    table.sort scan.user_tokens

    assert.same { "dad", "spam", "user"}, scan.text_tokens
    assert.same {
      "e.spammer@example.com"
      "el.spammer"
      "er.example.com"
    }, scan.user_tokens

    assert.true (scan\train "spam")

  it "detects a user", ->
    spam_user = factory.Users {
      email: "father@viagra.com"
    }
    profile = spam_user\get_user_profile!
    profile\update bio: "<ul> <li>buy drugs</li> <li>eat viagra</li> <li>online sex shop to buy the best sex toys</li> </ul>"

    SpamScans\refresh_for_user(spam_user)\train "spam"

    ham_user = factory.Users { }
    profile = ham_user\get_user_profile!
    profile\update bio: "<p>here is my <b>beautiful</b> art please like it</p>"

    SpamScans\refresh_for_user(ham_user)\train "ham"

    do
      -- a regular user
      user = factory.Users { }
      profile = user\get_user_profile!
      profile\update bio: "<strong>hello my art is good</strong>"

      scan = SpamScans\refresh_for_user(user)
      assert scan.score < 0.5, "scan is not spam"
      assert.same SpamScans.review_statuses.default, scan.review_status

    do
      -- a spammer
      user = factory.Users { }
      profile = user\get_user_profile!
      profile\update bio: "sex pills and drugs buy now"

      scan = SpamScans\refresh_for_user(user)
      assert scan.score > 0.5, "scan is spam"
      assert.same SpamScans.review_statuses.needs_review, scan.review_status


