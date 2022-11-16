-- Generated schema dump: (do not edit)
--
-- CREATE TABLE community_posts (
--   id integer NOT NULL,
--   topic_id integer NOT NULL,
--   user_id integer NOT NULL,
--   parent_post_id integer,
--   post_number integer DEFAULT 0 NOT NULL,
--   depth integer DEFAULT 0 NOT NULL,
--   deleted boolean DEFAULT false NOT NULL,
--   body text NOT NULL,
--   down_votes_count integer DEFAULT 0 NOT NULL,
--   up_votes_count integer DEFAULT 0 NOT NULL,
--   edits_count integer DEFAULT 0 NOT NULL,
--   last_edited_at timestamp without time zone,
--   deleted_at timestamp without time zone,
--   created_at timestamp without time zone NOT NULL,
--   updated_at timestamp without time zone NOT NULL,
--   status smallint DEFAULT 1 NOT NULL,
--   moderation_log_id integer,
--   body_format smallint DEFAULT 1 NOT NULL,
--   pin_position integer,
--   popularity_score integer DEFAULT 0
-- );
-- ALTER TABLE ONLY community_posts
--   ADD CONSTRAINT community_posts_moderation_log_id_key UNIQUE (moderation_log_id);
-- ALTER TABLE ONLY community_posts
--   ADD CONSTRAINT community_posts_pkey PRIMARY KEY (id);
-- CREATE INDEX community_posts_parent_post_id_popularity_score_idx ON community_posts USING btree (parent_post_id, popularity_score) WHERE ((popularity_score IS NOT NULL) AND (parent_post_id IS NOT NULL));
-- CREATE UNIQUE INDEX community_posts_parent_post_id_post_number_idx ON community_posts USING btree (parent_post_id, post_number);
-- CREATE INDEX community_posts_parent_post_id_status_post_number_idx ON community_posts USING btree (parent_post_id, status, post_number);
-- CREATE INDEX community_posts_topic_id_id_idx ON community_posts USING btree (topic_id, id) WHERE (NOT deleted);
-- CREATE UNIQUE INDEX community_posts_topic_id_parent_post_id_depth_post_number_idx ON community_posts USING btree (topic_id, parent_post_id, depth, post_number);
-- CREATE INDEX community_posts_topic_id_parent_post_id_depth_status_post_numbe ON community_posts USING btree (topic_id, parent_post_id, depth, status, post_number);
-- CREATE INDEX community_posts_topic_id_popularity_score_idx ON community_posts USING btree (topic_id, popularity_score) WHERE (popularity_score IS NOT NULL);
-- CREATE INDEX community_posts_user_id_id_idx ON community_posts USING btree (user_id, id);
--
class Posts extends require "community.models.posts"
  url_params: =>
    if @is_topic_post! and not @get_topic!.permanent
      @get_topic!\url_params!
    else
      "community.post", post_id: @id

  in_topic_url_params: (r) =>
    import POSTS_PER_PAGE from require "community.limits"

    topic = @get_topic!
    route, url_params, params = topic\url_params!
    root = @get_root_ancestor! or @
    offset = math.floor((root.post_number - 1) / POSTS_PER_PAGE) * POSTS_PER_PAGE

    if offset > 0
      params or={}
      params.after = offset

    nil, r\build_url r\url_for(route, url_params, params), {
      fragment: "post-#{@id}"
    }

  notification_targets: =>
    -- if the editor of the community is creating a new topic the generate a
    -- notification for everyone in the streak.
    poster = @get_user!

    extra = if @is_topic_post!
      topic = @get_topic!
      category = topic\get_category!
      streak = category\get_streak!

      if streak\is_host poster
        out = {}
        for page in streak\find_participants(pending: false)\each_page!
          for suser in *page
            table.insert out, {
              "topic"
              suser\get_user!
              category
              topic
            }

        out

    super extra

  send_notifications: =>
    import Notifications from require "models"

    for {kind, user, object, related_object} in *@notification_targets!
      notification_type = "community_#{kind}"
      continue unless Notifications.types[notification_type]
      target = object or @
      associated = related_object or object and @ or nil
      Notifications\notify_for user, target, notification_type, associated

  extract_text: =>
    import extract_text from require "helpers.html"
    extract_text @body

  allowed_to_reply: (user, ...) =>
    if user and user\is_suspended!
      return false

    super user, ...


