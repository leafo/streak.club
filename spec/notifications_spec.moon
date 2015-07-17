import
  load_test_server
  close_test_server
  from require "lapis.spec.server"

db = require "lapis.db"

import truncate_tables from require "lapis.spec.db"

import
  Users
  Notifications
  NotificationObjects
  Submissions
  SubmissionComments from require "models"

factory = require "spec.factory"
import request, request_as from require "spec.helpers"

describe "notifications", ->
  local current_user

  setup ->
    load_test_server!

  teardown ->
    close_test_server!

  before_each ->
    truncate_tables Users, Notifications, Submissions, SubmissionComments,
      NotificationObjects
    current_user = factory.Users!

  it "should create a new notification", ->
    submission = factory.Submissions!
    Notifications\notify_for current_user, submission, "comment"

    notifications = Notifications\select!
    assert.same 1, #notifications
    n = unpack notifications
    assert.same 1, n.count
    assert.same submission.id, n.object_id
    assert.same Notifications.object_types.submission, n.object_type
    assert.same current_user.id, n.user_id

  it "should increment notifications", ->
    submission = factory.Submissions!
    for i=1,5
      Notifications\notify_for current_user, submission, "comment"

    notifications = Notifications\select!
    assert.same 1, #notifications

  it "should not have notifications interfere", ->
    submission = factory.Submissions!
    other_submission = factory.Submissions!
    other_user = factory.Users!

    assert.same "create", (Notifications\notify_for current_user, submission, "comment")
    assert.same "create", (Notifications\notify_for other_user, submission, "comment")

    assert.same "create", (Notifications\notify_for current_user, other_submission, "comment")
    assert.same "create", (Notifications\notify_for other_user, other_submission, "comment")

    assert.same "update", (Notifications\notify_for current_user, other_submission, "comment")
    assert.same "update", (Notifications\notify_for other_user, submission, "comment")

    assert.same 4, #Notifications\select!
    assert.same 6, unpack(db.query "select sum(count) from notifications").sum

  it "should create a new notification after notification has been seen", ->
    submission = factory.Submissions!
    Notifications\notify_for current_user, submission, "comment"
    unpack(Notifications\select!)\update seen: true

    Notifications\notify_for current_user, submission, "comment"

    notifications = Notifications\select!
    assert.same 2, #notifications

  it "should create notification with associated object", ->
    submission = factory.Submissions!
    comment = factory.SubmissionComments submission_id: submission.id
    Notifications\notify_for current_user, submission, "comment", comment

    objects = NotificationObjects\select!
    assert.same 1, #objects
    object = unpack objects
    assert.same comment.id, object.object_id
    assert.same NotificationObjects.object_types.submission_comment, object.object_type

    -- do it again no big woop
    Notifications\notify_for current_user, submission, "comment", comment

  it "should increment notification with associated object #ddd", ->
    submission = factory.Submissions!
    comment = factory.SubmissionComments submission_id: submission.id

    for i=1,2
      comment = factory.SubmissionComments submission_id: submission.id
      Notifications\notify_for current_user, submission, "comment", comment

    objects = NotificationObjects\select!
    assert.same 2, #objects

  it "should undo notification", ->
    Notifications\notify_for current_user, factory.Submissions!, "comment"

    submission = factory.Submissions!
    _, note = Notifications\notify_for current_user, submission, "comment"
    note\mark_seen!

    _, note2 = Notifications\notify_for current_user, submission, "comment"
    Notifications\undo_notify current_user, submission, "comment"

    assert.same 2, #Notifications\select!
    assert.falsy Notifications\find note2.id

  it "views empty notificadtions page", ->
    status, res = request_as current_user, "/notifications"
    assert.same 200, status


  it "views empty notifications page with notifications", ->
    Notifications\notify_for current_user, factory.Submissions!, "comment"
    Notifications\notify_for current_user, factory.Submissions!, "comment"

    status, res = request_as current_user, "/notifications"
    assert.same 200, status




