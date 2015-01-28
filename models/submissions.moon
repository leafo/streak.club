db = require "lapis.db"
import Model, enum from require "lapis.db.model"

import slugify from require "lapis.util"

class Submissions extends Model
  @timestamp: true

  @relations: {
    {"user", belongs_to: "Users"}
  }

  @user_ratings: enum {
    good: 1
    neutral: 2
    bad: 3
  }

  @preload_streaks: (submissions) =>
    import StreakSubmissions, Streaks from require "models"

    submission_ids = [s.id for s in *submissions]
    streak_submits = StreakSubmissions\find_all submission_ids, {
      key: "submission_id"
    }

    Streaks\include_in streak_submits, "streak_id"

    streaks_by_submission_id = {}
    submits_by_submission_id = {}
    for submit in *streak_submits
      streaks_by_submission_id[submit.submission_id] or= {}
      table.insert streaks_by_submission_id[submit.submission_id], submit.streak

      submits_by_submission_id[submit.submission_id] or= {}
      table.insert submits_by_submission_id[submit.submission_id], submit

    for submission in *submissions
      submission.streaks = streaks_by_submission_id[submission.id] or {}
      submission.streak_submissions = submits_by_submission_id[submission.id] or {}

    submissions, [s.streak for s in *streak_submits]

  @preload_tags: (submissions) =>
    import SubmissionTags from require "models"
    submission_ids = [s.id for s in *submissions]
    tags = SubmissionTags\find_all submission_ids, key: "submission_id"
    tags_by_submission_id = {}
    for t in *tags
      tags_by_submission_id[t.submission_id] or= {}
      table.insert tags_by_submission_id[t.submission_id], t

    for s in *submissions
      s.tags = tags_by_submission_id[s.id] or {}

    submissions

  @preload_for_list: (submissions, opts={}) =>
    import Users, Uploads, SubmissionLikes from require "models"

    Uploads\preload_objects submissions

    things_with_users = [s for s in *submissions]

    unless opts.streaks == false
      _, streaks = @preload_streaks submissions

      for streak in *streaks
        table.insert things_with_users, streak

    @preload_tags submissions

    Users\include_in things_with_users, "user_id", {
      fields: "id, username, slug, display_name, email"
    }

    if user = opts.likes_for
      SubmissionLikes\include_in submissions, "submission_id", flip: true, where: {
        user_id: user.id
      }

    submissions

  allowed_to_view: (user) =>
    true

  allowed_to_edit: (user) =>
    return false unless user
    return true if user\is_admin!
    user.id == @user_id

  allowed_to_comment: (user) =>
    return false unless user
    return false unless @allow_comments
    true

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

  delete: =>
    res = super!
    if res.affected_rows and res.affected_rows > 0
      import
        SubmissionLikes
        SubmissionTags
        StreakSubmissions
        Uploads
        from require "models"

      for model in *{SubmissionLikes, SubmissionTags, StreakSubmissions}
        db.delete model\table_name!, submission_id: @id

      uploads = Uploads\select [[
        where object_type = ? and object_id = ?
      ]], Uploads.object_types.submission, @id

      for u in *uploads
        u\delete!

    res

  find_comments: (opts={}) =>
    import SubmissionComments, Users from require "models"
    SubmissionComments\paginated [[
      where submission_id = ? and not deleted
      order by id desc
    ]], @id, {
      per_page: opts.per_page
      prepare_results: (comments) ->
        Users\include_in comments, "user_id"
        comments
    }

  find_likes: (opts={}) =>
    import SubmissionLikes, Users from require "models"
    SubmissionLikes\paginated [[
      where submission_id = ?
      order by created_at desc
    ]], @id, {
      per_page: opts.per_page
      prepare_results: (likes) ->
        Users\include_in likes, "user_id"
        likes
    }

  meta_title: =>
    user = @get_user!

    if @title
      "#{@title} by #{user\name_for_display!}"
    else
      streaks = table.concat [s.title for s in *@get_streaks!], ", "
      "A submission for #{streaks} by #{user\name_for_display!}"

  slug: =>
    if @title
      slugify @meta_title!
