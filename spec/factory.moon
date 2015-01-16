
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
  opts.description or= "<p>streak descdription #{counter}</p>"
  opts.rate = "daily"
  opts.hour_offset or= 0
  opts.publish_status or= "published"

  if state = opts.state
    opts.state = nil
    switch state
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
    submission = Submissions!
    opts.submission_id = submission.id
    opts.user_id = submission.user_id

  opts.submit_time = db.raw "date_trunc('second', now())"

  opts.streak_id or= Streaks!.id
  models.StreakSubmissions\create opts

{ :Users, :Streaks, :Submissions, :StreakUsers, :StreakSubmissions }
