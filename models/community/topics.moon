
-- Generated schema dump: (do not edit)
--
-- CREATE TABLE community_topics (
--   id integer NOT NULL,
--   category_id integer,
--   user_id integer,
--   title character varying(255),
--   slug character varying(255),
--   last_post_id integer,
--   locked boolean DEFAULT false NOT NULL,
--   sticky boolean DEFAULT false NOT NULL,
--   permanent boolean DEFAULT false NOT NULL,
--   deleted boolean DEFAULT false NOT NULL,
--   posts_count integer DEFAULT 0 NOT NULL,
--   deleted_posts_count integer DEFAULT 0 NOT NULL,
--   root_posts_count integer DEFAULT 0 NOT NULL,
--   views_count integer DEFAULT 0 NOT NULL,
--   category_order integer DEFAULT 0 NOT NULL,
--   deleted_at timestamp without time zone,
--   created_at timestamp without time zone NOT NULL,
--   updated_at timestamp without time zone NOT NULL,
--   status smallint DEFAULT 1 NOT NULL,
--   tags character varying(255)[],
--   rank_adjustment integer DEFAULT 0 NOT NULL,
--   protected boolean DEFAULT false NOT NULL,
--   data jsonb
-- );
-- ALTER TABLE ONLY community_topics
--   ADD CONSTRAINT community_topics_pkey PRIMARY KEY (id);
-- CREATE INDEX community_topics_category_id_idx ON community_topics USING btree (category_id) WHERE (category_id IS NOT NULL);
-- CREATE INDEX community_topics_category_id_sticky_status_category_order_idx ON community_topics USING btree (category_id, sticky, status, category_order) WHERE ((NOT deleted) AND (category_id IS NOT NULL));
-- CREATE INDEX community_topics_user_id_idx ON community_topics USING btree (user_id) WHERE (user_id IS NOT NULL);
--
class Topics extends require "community.models.topics"
  url_params: (req, ...) =>
    if @slug and @slug != ""
      "community.topic", { topic_id: @id, topic_slug: @slug }, ...
    else
      "community.topic", { topic_id: @id }, ...

  name_for_display: =>
    @title or "anonymous topic"

  is_single_page: =>
    import POSTS_PER_PAGE from require "community.limits"
    @root_posts_count <= POSTS_PER_PAGE

  last_page_url_params: =>
    route, params, query = @url_params!
    unless @is_single_page!
      query or= {}
      query.after = nil
      query.before = @root_posts_count + 1

    route, params, query

  latest_post_url_params: (r, ...) =>
    route, params, get = @url_params r, ...
    get or= {}
    get.before = @find_latest_root_post!.post_number + 1
    get.after = nil
    route, params, get

  allowed_to_post: (user, ...) =>
    if user and user\is_suspended!
      return false

    super user, ...

