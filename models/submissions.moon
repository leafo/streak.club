db = require "lapis.db"
import Model from require "lapis.db.model"

class Submissions extends Model
  @timestamp: true

  @relations: {
    {"user", belongs_to: "Users"}
  }

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


  @preload_for_list: (submissions, opts={}) =>
    import Users, Uploads from require "models"

    Uploads\preload_objects submissions

    things_with_users = [s for s in *submissions]

    unless opts.streaks == false
      _, streaks = @preload_streaks submissions

      for streak in *streaks
        table.insert things_with_users, streak

    Users\include_in things_with_users, "user_id", {
      fields: "id, username, slug, display_name, email"
    }

    submissions

  allowed_to_view: (user) =>
    true

  allowed_to_edit: (user) =>
    return false unless user
    return true if user\is_admin!
    user.id == @user_id

  get_streaks: =>
    unless @streaks
      import StreakSubmissions, Streaks from require "models"
      submits = StreakSubmissions\select "where submission_id = ?", @id
      Streaks\include_in submits, "streak_id"
      @streaks = [s.streak for s in *submits]

    @streaks

  get_uploads: =>
    unless @uploads
      import Uploads from require "models"
      @uploads = Uploads\select "
        where object_type = ? and object_id = ? and ready
        order by position
      ", Uploads.object_types.submission, @id

    @uploads

  get_tags: =>
    unless @tags
      import SubmissionTags from require "models"
      @tags = SubmissionTags\select "where submission_id = ?", @id

    @tags

  url_params: =>
    "view_submission", id: @id

  set_tags: (tags_str) =>
    import SubmissionTags from require "models"

    tags = SubmissionTags\parse tags_str
    old_tags = { tag.slug, true for tag in *SubmissionTags\select "where submission_id = ?", @id }
    new_tags = { SubmissionTags\slugify(tag), true for tag in *tags }

    -- filter and mark ones to add and ones to remove
    for slug in pairs new_tags
      if slug\match("^%-*$") or old_tags[slug]
        new_tags[slug] = nil
        old_tags[slug] = nil

    if next old_tags
      slugs = table.concat [db.escape_literal slug for slug in pairs old_tags], ","
      db.delete SubmissionTags\table_name!, "submission_id = ? and slug in (#{slugs})", @id

    for slug in pairs new_tags
      SubmissionTags\create {
        submission_id: @id
        :slug
      }

