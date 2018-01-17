b = require "lapis.db"
import Model, enum from require "lapis.db.model"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE submission_comments (
--   id integer NOT NULL,
--   submission_id integer NOT NULL,
--   user_id integer NOT NULL,
--   body text NOT NULL,
--   edited_at timestamp without time zone,
--   deleted boolean DEFAULT false NOT NULL,
--   created_at timestamp without time zone NOT NULL,
--   updated_at timestamp without time zone NOT NULL
-- );
-- ALTER TABLE ONLY submission_comments
--   ADD CONSTRAINT submission_comments_pkey PRIMARY KEY (id);
-- CREATE INDEX submission_comments_submission_id_id_idx ON submission_comments USING btree (submission_id, id) WHERE (NOT deleted);
-- CREATE INDEX submission_comments_user_id_id_idx ON submission_comments USING btree (user_id, id) WHERE (NOT deleted);
--
class SubmissionComments extends Model
  @timestamp: true

  @relations: {
    {"user", belongs_to: "Users"}
    {"submission", belongs_to: "Submissions"}
  }

  @sources: enum {
    defaut: 1
    quick: 2
  }

  @create: (opts) =>
    if opts.source
      opts.source = @sources\for_db opts.source

    super opts

  @load_mentioned_users: (comments) =>
    import Users from require "models"
    all_usernames = {}
    usernames_by_comment = {}

    for comment in *comments
      usernames = @_parse_usernames comment.body
      if next usernames
        usernames_by_comment[comment.id] = usernames
        for u in *usernames
          table.insert all_usernames, u


    users = Users\find_all all_usernames, key: "username"
    users_by_username = {u.username, u for u in *users}

    for comment in *comments
      comment.mentioned_users = for uname in *usernames_by_comment[comment.id] or {}
        continue unless users_by_username[uname]
        users_by_username[uname]

    comments

  @_parse_usernames: (body) =>
    [username for username in body\gmatch "@([%w-_]+)"]

  get_mentioned_users: =>
    unless @mentioned_users
      usernames = @@_parse_usernames @body
      import Users from require "models"
      @mentioned_users = Users\find_all usernames, key: "username"

    @mentioned_users

  filled_body: (r) =>
    body = @body

    if m = @get_mentioned_users!
      mentions_by_username = {u.username, u for u in *m}
      import escape from require "lapis.html"

      body = body\gsub "@([%w-_]+)", (username) ->
        user = mentions_by_username[username]
        return "@#{username}" unless user
        "<a href='#{escape r\build_url r\url_for user}'>@#{escape user\name_for_display!}</a>"

    body

  allowed_to_edit: (user) =>
    return false unless user
    return true if user\is_admin!
    user.id == @user_id

  allowed_to_delete: (user) =>
    return true if @allowed_to_edit user
    if user and user.id == @get_submission!.user_id
      return true
    false

  url_params: =>
    submission = @get_submission!
    "view_submission", id: submission.id

  extract_text: =>
    import extract_text from require "web_sanitize"
    import decode_html_entities from require "helpers.html"
    decode_html_entities extract_text @body

