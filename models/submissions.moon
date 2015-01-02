db = require "lapis.db"
import Model from require "lapis.db.model"

class Submissions extends Model
  @timestamp: true

  @preload_streaks: (submissions) =>
    import StreakSubmissions, Streaks from require "models"

    submission_ids = [s.id for s in *submissions]
    streak_submits = StreakSubmissions\find_all submission_ids, {
      key: "submission_id"
    }

    Streaks\include_in streak_submits, "streak_id"

    s_by_s_id = {}
    for submit in *streak_submits
      s_by_s_id[submit.submission_id] or= {}
      table.insert s_by_s_id[submit.submission_id], submit.streak

    for submission in *submissions
      submission.streaks = s_by_s_id[submission.id] or {}

    submissions, [s.streak for s in *streak_submits]

