
-- Generated schema dump: (do not edit)
--
-- CREATE TABLE community_categories (
--   id integer NOT NULL,
--   title character varying(255),
--   slug character varying(255),
--   user_id integer,
--   parent_category_id integer,
--   last_topic_id integer,
--   topics_count integer DEFAULT 0 NOT NULL,
--   deleted_topics_count integer DEFAULT 0 NOT NULL,
--   views_count integer DEFAULT 0 NOT NULL,
--   short_description text,
--   description text,
--   rules text,
--   membership_type integer,
--   voting_type integer,
--   archived boolean DEFAULT false NOT NULL,
--   hidden boolean DEFAULT false NOT NULL,
--   created_at timestamp without time zone NOT NULL,
--   updated_at timestamp without time zone NOT NULL,
--   category_groups_count integer DEFAULT 0 NOT NULL,
--   approval_type smallint,
--   "position" integer DEFAULT 0 NOT NULL,
--   directory boolean DEFAULT false NOT NULL,
--   topic_posting_type smallint,
--   category_order_type smallint DEFAULT 1 NOT NULL
-- );
-- ALTER TABLE ONLY community_categories
--   ADD CONSTRAINT community_categories_pkey PRIMARY KEY (id);
-- CREATE INDEX community_categories_parent_category_id_position_idx ON community_categories USING btree (parent_category_id, "position") WHERE (parent_category_id IS NOT NULL);
--
class Categories extends require "community.models.categories"
  @get_relation_model: (name) =>
    require("models")[name] or @__parent\get_relation_model name

  @relations: {
    {"streak", has_one: "Streaks", key: "community_category_id"}
  }

  edit_options: =>
    {}

  url_params: =>
    streak = @get_streak!
    "community.streak", id: streak.id, slug: streak\slug!

  allowed_to_view: (user, ...) =>
    streak = @get_streak!

    unless streak\allowed_to_view(user) and streak\has_community!
      return false

    super user, ...

  name_for_display: =>
    return @title if @title
    streak = @get_streak!
    if streak
      streak.title .. " discussion"
    else
      "unnamed community"

  allowed_to_post_topic: (user, ...) =>
    if user and user\is_suspended!
      return false

    super user, ...


