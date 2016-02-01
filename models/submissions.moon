db = require "lapis.db"
import Model, enum from require "lapis.db.model"

import slugify from require "lapis.util"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE submissions (
--   id integer NOT NULL,
--   user_id integer NOT NULL,
--   title character varying(255),
--   description text,
--   published boolean DEFAULT true NOT NULL,
--   deleted boolean DEFAULT false NOT NULL,
--   created_at timestamp without time zone NOT NULL,
--   updated_at timestamp without time zone NOT NULL,
--   likes_count integer DEFAULT 0 NOT NULL,
--   user_rating integer DEFAULT 2 NOT NULL,
--   allow_comments boolean DEFAULT true NOT NULL,
--   comments_count integer DEFAULT 0 NOT NULL,
--   hidden boolean DEFAULT false NOT NULL
-- );
-- ALTER TABLE ONLY submissions
--   ADD CONSTRAINT submissions_pkey PRIMARY KEY (id);
-- CREATE INDEX submissions_user_id_id_idx ON submissions USING btree (user_id, id);
-- CREATE INDEX submissions_user_id_id_not_hidden_idx ON submissions USING btree (user_id, id) WHERE (NOT hidden);
-- CREATE INDEX submissions_user_id_idx ON submissions USING btree (user_id);
--
class Submissions extends Model
  @timestamp: true

  @relations: {
    {"user", belongs_to: "Users"}
    {"featured_submission", has_one: "FeaturedSubmissions"}
    {"streak_submissions", has_many: "StreakSubmissions"}
    {"tags", has_many: "SubmissionTags"}
  }

  @user_ratings: enum {
    good: 1
    neutral: 2
    bad: 3
  }

  @preload_streaks: (submissions) =>
    import StreakSubmissions from require "models"

    @preload_relation submissions, "streak_submissions"
    streak_submits = {}
    for sub in *submissions
      for streak_sub in *sub\get_streak_submissions!
        table.insert streak_submits, streak_sub

    StreakSubmissions\preload_relation streak_submits, "streak"

    for sub in *submissions
      sub.streaks = [s\get_streak! for s in *sub\get_streak_submissions!]

    streaks = [s\get_streak! for s in *streak_submits]
    submissions, [s.streak for s in *streak_submits]

  @preload_for_list: (submissions, opts={}) =>
    import Users, Uploads, SubmissionLikes from require "models"

    Uploads\preload_objects submissions

    things_with_users = [s for s in *submissions]

    unless opts.streaks == false
      _, streaks = @preload_streaks submissions

      for streak in *streaks
        table.insert things_with_users, streak


    Users\include_in things_with_users, "user_id", {
      fields: "id, username, slug, display_name, email"
    }

    @preload_relations submissions, "featured_submission", "tags"

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
      submits = @get_streak_submissions!
      import Streaks from require "models"
      Streaks\include_in submits, "streak_id"
      @streaks = for s in *submits
        s.streak.streak_submission = s
        s.streak

    @streaks

  get_uploads: =>
    unless @uploads
      import Uploads from require "models"
      @uploads = Uploads\select "
        where object_type = ? and object_id = ? and ready
        order by position
      ", Uploads.object_types.submission, @id

    @uploads

  url_params: =>
    slug = @slug!
    if slug
      "view_submission_slug", id: @id, :slug
    else
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
        user_id: @user_id
        submission_id: @id
        :slug
      }

  delete: =>
    return unless super!

    import
      SubmissionLikes
      SubmissionTags
      StreakSubmissions
      StreakUsers
      Streaks
      Uploads
      from require "models"

    db.update Streaks\table_name!, {
      submissions_count: db.raw "submissions_count - 1"
    }, db.interpolate_query "id in (select streak_id from streak_submissions where submission_id = ?)", @id

    streak_users = StreakUsers\select "
      where user_id = ? and
        streak_id in (select streak_id from streak_submissions where submission_id = ?)
    ", @user_id, @id

    for u in *streak_users
      u\update_streaks!

    for model in *{SubmissionLikes, SubmissionTags, StreakSubmissions}
      db.delete model\table_name!, submission_id: @id

    uploads = Uploads\select [[
      where object_type = ? and object_id = ?
    ]], Uploads.object_types.submission, @id

    for u in *uploads
      u\delete!

    true

  find_comments: (opts={}) =>
    import SubmissionComments, Users from require "models"
    SubmissionComments\paginated [[
      where submission_id = ? and not deleted
      order by id desc
    ]], @id, {
      per_page: opts.per_page
      prepare_results: (comments) ->
        SubmissionComments\load_mentioned_users comments
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

  meta_title: (for_twitter=false) =>
    user = @get_user!
    streaks = @get_streaks!

    name = if for_twitter
      handle = user\get_user_profile!\twitter_handle!
      handle = "@#{handle}" if handle
      handle

    name or= user\name_for_display!

    base = if @title
      "#{@title} by #{name}"
    else
      streak_names = table.concat [s.title for s in *streaks], ", "
      if for_twitter and #streaks == 1
        import StreakSubmissions from require "models"
        submit = StreakSubmissions\find {
          streak_id: streaks[1].id
          submission_id: @id
        }
        "Submission #{submit\unit_number!} for #{streak_names} by #{name}"
      else
        "A submission for #{streak_names} by #{name}"

    if #streaks == 1
      import StreakUsers from require "models"
      s_user = StreakUsers\find {
        streak_id: streaks[1].id
        user_id: @user_id
      }

      if s_user
        base ..= " (Streak #{s_user\get_current_streak!})"

    base

  slug: =>
    if @title
      user = @get_user!
      slugify "#{@title} by #{user\name_for_display!}"

  is_hidden_from: (user) =>
    return true if @hidden and not user

    if user
      return false, @hidden if user.id == @user_id
      return false, @hidden if user\is_admin!

    @hidden

  visible_streaks_for: (user, current_streak_id) =>
    return for streak in *@get_streaks!
      if current_streak_id == streak.id
        -- can see it if we're viewing streak
        streak
      elseif @allowed_to_edit user
        -- can see all streaks if we own submission
        streak
      else
        continue if streak\is_hidden_from @current_user
        streak


