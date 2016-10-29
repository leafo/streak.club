models = require "models"
db = require "lapis.db"

date = require "date"

import Model from require "lapis.db.model"
import slugify from require "lapis.util"

relative_day = (day_offset=0) ->
  d = date date(true)\getdate!
  d\adddays day_offset
  d\fmt models.Streaks.day_format_str

next_counter = do
  counters = setmetatable {}, __index: => 1
  (name) ->
    with counters[name]
      counters[name] += 1

next_email = ->
  "me-#{next_counter "email"}@example.com"

Users = (opts={}) ->
  opts.username or= "user-#{next_counter "username"}"
  opts.email or= next_email!
  opts.password or= "my-password"
  assert models.Users\create opts

Streaks = (opts={}) ->
  counter = next_counter "streak"

  opts.user_id or= Users!.id
  opts.title or= "streak-#{counter}"
  opts.short_description or= "short description for #{counter}"
  opts.description or= "<p>streak description #{counter}</p>"
  opts.rate = "daily"
  opts.hour_offset or= 0
  opts.publish_status or= "published"

  if state = opts.state
    opts.state = nil
    switch state
      when "first_unit"
        -- this makes it so it started at least 1 hour ago, at most 1:59
        opts.hour_offset = -date(true)\gethours! + 1
        opts.start_date = relative_day 0
        opts.end_date = relative_day 10
      when "during"
        opts.start_date = relative_day -10
        opts.end_date = relative_day 10
      when "before_start"
        opts.start_date = relative_day 10
        opts.end_date = relative_day 20
      when "after_end"
        opts.start_date = relative_day -20
        opts.end_date = relative_day -10
  else
    opts.start_date or= relative_day 0
    opts.end_date or= relative_day 20

  models.Streaks\create opts

Submissions = (opts={}) ->
  counter = next_counter "submission"

  opts.user_id or= Users!.id
  opts.title or= "Submission #{counter}"
  opts.description or= "hello world #{counter}"

  models.Submissions\create opts

StreakUsers = (opts={}) ->
  opts.streak_id or= Streaks!.id
  opts.user_id or= Users!.id
  models.StreakUsers\create opts

StreakSubmissions = (opts={}) ->
  unless opts.submission_id
    submission = Submissions user_id: opts.user_id
    opts.submission_id = submission.id
    opts.user_id = submission.user_id

  opts.submit_time or= db.raw "date_trunc('second', now() at time zone 'utc')"

  opts.streak_id or= Streaks!.id
  models.StreakSubmissions\create opts

SubmissionComments = (opts={}) ->
  opts.user_id or= Users!.id
  opts.body or= "my comment #{next_counter "submission_comment"}"
  opts.submission_id or= Submissions!.id
  comment = models.SubmissionComments\create opts
  comment\get_submission!\update {
    comments_count: db.raw "comments_count + 1"
  }, timestamp: false

  comment

Followings = (opts={}) ->
  opts.source_user_id or= Users!.id
  opts.dest_user_id or= Users!.id
  models.Followings\create opts

ApiKeys = (opts={}) ->
  opts.user_id or= Users!.id
  opts.source or= "web"
  models.ApiKeys\create opts


community_models = require "community.models"
community_factory = require "community.spec.factory"

community = { }
community.Categories = (opts={}) ->
  streak = opts.streak or Streaks!
  category = community_factory.Categories user_id: streak.user_id
  streak\update community_category_id: category.id
  category

community.Topics = community_factory.Topics
community.Posts = community_factory.Posts

{ :Users, :Streaks, :Submissions, :StreakUsers, :StreakSubmissions,
  :SubmissionComments, :Followings, :ApiKeys, :community }
