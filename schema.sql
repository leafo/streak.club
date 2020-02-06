--
-- PostgreSQL database dump
--

-- Dumped from database version 12.1
-- Dumped by pg_dump version 12.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: api_keys; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.api_keys (
    id integer NOT NULL,
    key character varying(255) NOT NULL,
    source integer DEFAULT 0 NOT NULL,
    user_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.api_keys OWNER TO postgres;

--
-- Name: api_keys_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.api_keys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.api_keys_id_seq OWNER TO postgres;

--
-- Name: api_keys_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.api_keys_id_seq OWNED BY public.api_keys.id;


--
-- Name: community_activity_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.community_activity_logs (
    id integer NOT NULL,
    user_id integer NOT NULL,
    object_type integer DEFAULT 0 NOT NULL,
    object_id integer NOT NULL,
    publishable boolean DEFAULT false NOT NULL,
    action integer DEFAULT 0 NOT NULL,
    data text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.community_activity_logs OWNER TO postgres;

--
-- Name: community_activity_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.community_activity_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.community_activity_logs_id_seq OWNER TO postgres;

--
-- Name: community_activity_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.community_activity_logs_id_seq OWNED BY public.community_activity_logs.id;


--
-- Name: community_bans; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.community_bans (
    object_type integer DEFAULT 0 NOT NULL,
    object_id integer NOT NULL,
    banned_user_id integer NOT NULL,
    reason text,
    banning_user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.community_bans OWNER TO postgres;

--
-- Name: community_blocks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.community_blocks (
    blocking_user_id integer NOT NULL,
    blocked_user_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.community_blocks OWNER TO postgres;

--
-- Name: community_bookmarks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.community_bookmarks (
    user_id integer NOT NULL,
    object_type integer DEFAULT 0 NOT NULL,
    object_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.community_bookmarks OWNER TO postgres;

--
-- Name: community_categories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.community_categories (
    id integer NOT NULL,
    title character varying(255),
    slug character varying(255),
    user_id integer,
    parent_category_id integer,
    last_topic_id integer,
    topics_count integer DEFAULT 0 NOT NULL,
    deleted_topics_count integer DEFAULT 0 NOT NULL,
    views_count integer DEFAULT 0 NOT NULL,
    short_description text,
    description text,
    rules text,
    membership_type integer,
    voting_type integer,
    archived boolean DEFAULT false NOT NULL,
    hidden boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    category_groups_count integer DEFAULT 0 NOT NULL,
    approval_type smallint,
    "position" integer DEFAULT 0 NOT NULL,
    directory boolean DEFAULT false NOT NULL,
    topic_posting_type smallint,
    category_order_type smallint DEFAULT 1 NOT NULL
);


ALTER TABLE public.community_categories OWNER TO postgres;

--
-- Name: community_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.community_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.community_categories_id_seq OWNER TO postgres;

--
-- Name: community_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.community_categories_id_seq OWNED BY public.community_categories.id;


--
-- Name: community_category_group_categories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.community_category_group_categories (
    category_group_id integer NOT NULL,
    category_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.community_category_group_categories OWNER TO postgres;

--
-- Name: community_category_groups; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.community_category_groups (
    id integer NOT NULL,
    title character varying(255),
    user_id integer,
    categories_count integer DEFAULT 0 NOT NULL,
    description text,
    rules text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.community_category_groups OWNER TO postgres;

--
-- Name: community_category_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.community_category_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.community_category_groups_id_seq OWNER TO postgres;

--
-- Name: community_category_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.community_category_groups_id_seq OWNED BY public.community_category_groups.id;


--
-- Name: community_category_members; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.community_category_members (
    user_id integer NOT NULL,
    category_id integer NOT NULL,
    accepted boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.community_category_members OWNER TO postgres;

--
-- Name: community_category_post_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.community_category_post_logs (
    category_id integer NOT NULL,
    post_id integer NOT NULL
);


ALTER TABLE public.community_category_post_logs OWNER TO postgres;

--
-- Name: community_category_tags; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.community_category_tags (
    id integer NOT NULL,
    category_id integer NOT NULL,
    slug character varying(255) NOT NULL,
    label text,
    color character varying(255),
    image_url character varying(255),
    tag_order integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.community_category_tags OWNER TO postgres;

--
-- Name: community_category_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.community_category_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.community_category_tags_id_seq OWNER TO postgres;

--
-- Name: community_category_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.community_category_tags_id_seq OWNED BY public.community_category_tags.id;


--
-- Name: community_moderation_log_objects; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.community_moderation_log_objects (
    moderation_log_id integer NOT NULL,
    object_type integer DEFAULT 0 NOT NULL,
    object_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.community_moderation_log_objects OWNER TO postgres;

--
-- Name: community_moderation_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.community_moderation_logs (
    id integer NOT NULL,
    category_id integer,
    object_type integer DEFAULT 0 NOT NULL,
    object_id integer NOT NULL,
    user_id integer NOT NULL,
    action character varying(255) NOT NULL,
    reason text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    data jsonb
);


ALTER TABLE public.community_moderation_logs OWNER TO postgres;

--
-- Name: community_moderation_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.community_moderation_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.community_moderation_logs_id_seq OWNER TO postgres;

--
-- Name: community_moderation_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.community_moderation_logs_id_seq OWNED BY public.community_moderation_logs.id;


--
-- Name: community_moderators; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.community_moderators (
    user_id integer NOT NULL,
    object_type integer NOT NULL,
    object_id integer NOT NULL,
    admin boolean DEFAULT false NOT NULL,
    accepted boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.community_moderators OWNER TO postgres;

--
-- Name: community_pending_posts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.community_pending_posts (
    id integer NOT NULL,
    category_id integer,
    topic_id integer,
    user_id integer NOT NULL,
    parent_post_id integer,
    status smallint NOT NULL,
    body text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    title character varying(255),
    body_format smallint DEFAULT 1 NOT NULL
);


ALTER TABLE public.community_pending_posts OWNER TO postgres;

--
-- Name: community_pending_posts_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.community_pending_posts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.community_pending_posts_id_seq OWNER TO postgres;

--
-- Name: community_pending_posts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.community_pending_posts_id_seq OWNED BY public.community_pending_posts.id;


--
-- Name: community_post_edits; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.community_post_edits (
    id integer NOT NULL,
    post_id integer NOT NULL,
    user_id integer NOT NULL,
    body_before text NOT NULL,
    reason text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    body_format smallint DEFAULT 1 NOT NULL
);


ALTER TABLE public.community_post_edits OWNER TO postgres;

--
-- Name: community_post_edits_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.community_post_edits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.community_post_edits_id_seq OWNER TO postgres;

--
-- Name: community_post_edits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.community_post_edits_id_seq OWNED BY public.community_post_edits.id;


--
-- Name: community_post_reports; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.community_post_reports (
    id integer NOT NULL,
    category_id integer,
    post_id integer NOT NULL,
    user_id integer NOT NULL,
    category_report_number integer DEFAULT 0 NOT NULL,
    moderating_user_id integer,
    status integer DEFAULT 0 NOT NULL,
    reason integer DEFAULT 0 NOT NULL,
    body text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    moderated_at timestamp without time zone
);


ALTER TABLE public.community_post_reports OWNER TO postgres;

--
-- Name: community_post_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.community_post_reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.community_post_reports_id_seq OWNER TO postgres;

--
-- Name: community_post_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.community_post_reports_id_seq OWNED BY public.community_post_reports.id;


--
-- Name: community_posts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.community_posts (
    id integer NOT NULL,
    topic_id integer NOT NULL,
    user_id integer NOT NULL,
    parent_post_id integer,
    post_number integer DEFAULT 0 NOT NULL,
    depth integer DEFAULT 0 NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    body text NOT NULL,
    down_votes_count integer DEFAULT 0 NOT NULL,
    up_votes_count integer DEFAULT 0 NOT NULL,
    edits_count integer DEFAULT 0 NOT NULL,
    last_edited_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    status smallint DEFAULT 1 NOT NULL,
    moderation_log_id integer,
    body_format smallint DEFAULT 1 NOT NULL,
    pin_position integer
);


ALTER TABLE public.community_posts OWNER TO postgres;

--
-- Name: community_posts_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.community_posts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.community_posts_id_seq OWNER TO postgres;

--
-- Name: community_posts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.community_posts_id_seq OWNED BY public.community_posts.id;


--
-- Name: community_posts_search; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.community_posts_search (
    post_id integer NOT NULL,
    topic_id integer NOT NULL,
    category_id integer,
    posted_at timestamp without time zone NOT NULL,
    words tsvector
);


ALTER TABLE public.community_posts_search OWNER TO postgres;

--
-- Name: community_subscriptions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.community_subscriptions (
    object_type smallint NOT NULL,
    object_id integer NOT NULL,
    user_id integer NOT NULL,
    subscribed boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.community_subscriptions OWNER TO postgres;

--
-- Name: community_topic_participants; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.community_topic_participants (
    topic_id integer NOT NULL,
    user_id integer NOT NULL,
    posts_count integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.community_topic_participants OWNER TO postgres;

--
-- Name: community_topics; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.community_topics (
    id integer NOT NULL,
    category_id integer,
    user_id integer,
    title character varying(255),
    slug character varying(255),
    last_post_id integer,
    locked boolean DEFAULT false NOT NULL,
    sticky boolean DEFAULT false NOT NULL,
    permanent boolean DEFAULT false NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    posts_count integer DEFAULT 0 NOT NULL,
    deleted_posts_count integer DEFAULT 0 NOT NULL,
    root_posts_count integer DEFAULT 0 NOT NULL,
    views_count integer DEFAULT 0 NOT NULL,
    category_order integer DEFAULT 0 NOT NULL,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    status smallint DEFAULT 1 NOT NULL,
    tags character varying(255)[],
    rank_adjustment integer DEFAULT 0 NOT NULL,
    protected boolean DEFAULT false NOT NULL
);


ALTER TABLE public.community_topics OWNER TO postgres;

--
-- Name: community_topics_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.community_topics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.community_topics_id_seq OWNER TO postgres;

--
-- Name: community_topics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.community_topics_id_seq OWNED BY public.community_topics.id;


--
-- Name: community_user_category_last_seens; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.community_user_category_last_seens (
    user_id integer NOT NULL,
    category_id integer NOT NULL,
    category_order integer DEFAULT 0 NOT NULL,
    topic_id integer NOT NULL
);


ALTER TABLE public.community_user_category_last_seens OWNER TO postgres;

--
-- Name: community_user_topic_last_seens; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.community_user_topic_last_seens (
    user_id integer NOT NULL,
    topic_id integer NOT NULL,
    post_id integer NOT NULL
);


ALTER TABLE public.community_user_topic_last_seens OWNER TO postgres;

--
-- Name: community_users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.community_users (
    user_id integer NOT NULL,
    posts_count integer DEFAULT 0 NOT NULL,
    topics_count integer DEFAULT 0 NOT NULL,
    votes_count integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    flair character varying(255),
    recent_posts_count integer DEFAULT 0 NOT NULL,
    last_post_at timestamp without time zone
);


ALTER TABLE public.community_users OWNER TO postgres;

--
-- Name: community_votes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.community_votes (
    user_id integer NOT NULL,
    object_type integer NOT NULL,
    object_id integer NOT NULL,
    positive boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ip inet,
    counted boolean DEFAULT true NOT NULL,
    score integer
);


ALTER TABLE public.community_votes OWNER TO postgres;

--
-- Name: daily_audio_plays; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.daily_audio_plays (
    upload_id integer NOT NULL,
    date date NOT NULL,
    count integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.daily_audio_plays OWNER TO postgres;

--
-- Name: daily_upload_downloads; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.daily_upload_downloads (
    upload_id integer NOT NULL,
    date date NOT NULL,
    count integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.daily_upload_downloads OWNER TO postgres;

--
-- Name: exception_requests; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.exception_requests (
    id integer NOT NULL,
    exception_type_id integer NOT NULL,
    path text NOT NULL,
    method character varying(255) NOT NULL,
    referer text,
    ip character varying(255) NOT NULL,
    data text NOT NULL,
    msg text NOT NULL,
    trace text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.exception_requests OWNER TO postgres;

--
-- Name: exception_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.exception_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.exception_requests_id_seq OWNER TO postgres;

--
-- Name: exception_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.exception_requests_id_seq OWNED BY public.exception_requests.id;


--
-- Name: exception_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.exception_types (
    id integer NOT NULL,
    label text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    count integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.exception_types OWNER TO postgres;

--
-- Name: exception_types_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.exception_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.exception_types_id_seq OWNER TO postgres;

--
-- Name: exception_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.exception_types_id_seq OWNED BY public.exception_types.id;


--
-- Name: featured_streaks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.featured_streaks (
    streak_id integer NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.featured_streaks OWNER TO postgres;

--
-- Name: featured_submissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.featured_submissions (
    submission_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.featured_submissions OWNER TO postgres;

--
-- Name: followings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.followings (
    source_user_id integer NOT NULL,
    dest_user_id integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.followings OWNER TO postgres;

--
-- Name: lapis_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lapis_migrations (
    name character varying(255) NOT NULL
);


ALTER TABLE public.lapis_migrations OWNER TO postgres;

--
-- Name: notification_objects; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notification_objects (
    notification_id integer NOT NULL,
    object_type integer DEFAULT 0 NOT NULL,
    object_id integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.notification_objects OWNER TO postgres;

--
-- Name: notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notifications (
    id integer NOT NULL,
    user_id integer NOT NULL,
    type integer DEFAULT 0 NOT NULL,
    object_type integer DEFAULT 0 NOT NULL,
    object_id integer DEFAULT 0 NOT NULL,
    count integer DEFAULT 0 NOT NULL,
    seen boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.notifications OWNER TO postgres;

--
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.notifications_id_seq OWNER TO postgres;

--
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.notifications_id_seq OWNED BY public.notifications.id;


--
-- Name: notifications_user_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.notifications_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.notifications_user_id_seq OWNER TO postgres;

--
-- Name: notifications_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.notifications_user_id_seq OWNED BY public.notifications.user_id;


--
-- Name: related_streaks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.related_streaks (
    id integer NOT NULL,
    streak_id integer NOT NULL,
    other_streak_id integer NOT NULL,
    type smallint NOT NULL,
    reason text,
    "position" integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.related_streaks OWNER TO postgres;

--
-- Name: related_streaks_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.related_streaks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.related_streaks_id_seq OWNER TO postgres;

--
-- Name: related_streaks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.related_streaks_id_seq OWNED BY public.related_streaks.id;


--
-- Name: streak_submissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.streak_submissions (
    streak_id integer NOT NULL,
    submission_id integer NOT NULL,
    submit_time timestamp without time zone NOT NULL,
    user_id integer NOT NULL,
    late_submit boolean DEFAULT false NOT NULL
);


ALTER TABLE public.streak_submissions OWNER TO postgres;

--
-- Name: streak_user_notification_settings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.streak_user_notification_settings (
    user_id integer NOT NULL,
    streak_id integer NOT NULL,
    frequency smallint DEFAULT 1 NOT NULL,
    late_submit_reminded_at timestamp without time zone,
    join_email_at timestamp without time zone,
    start_email_at timestamp without time zone
);


ALTER TABLE public.streak_user_notification_settings OWNER TO postgres;

--
-- Name: streak_users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.streak_users (
    streak_id integer NOT NULL,
    user_id integer NOT NULL,
    submissions_count integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    current_streak integer,
    longest_streak integer,
    last_submitted_at timestamp without time zone,
    pending boolean DEFAULT false NOT NULL
);


ALTER TABLE public.streak_users OWNER TO postgres;

--
-- Name: streaks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.streaks (
    id integer NOT NULL,
    user_id integer NOT NULL,
    title character varying(255) NOT NULL,
    short_description text NOT NULL,
    description text NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    start_date date NOT NULL,
    end_date date,
    rate integer DEFAULT 0 NOT NULL,
    users_count integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    submissions_count integer DEFAULT 0 NOT NULL,
    hour_offset integer DEFAULT 0 NOT NULL,
    publish_status integer NOT NULL,
    category integer,
    twitter_hash text,
    late_submit_type integer DEFAULT 1 NOT NULL,
    membership_type integer DEFAULT 1 NOT NULL,
    pending_users_count integer DEFAULT 0 NOT NULL,
    last_deadline_email_at timestamp without time zone,
    last_late_submit_email_at timestamp without time zone,
    community_category_id integer,
    community_type smallint DEFAULT 1 NOT NULL
);


ALTER TABLE public.streaks OWNER TO postgres;

--
-- Name: streaks_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.streaks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.streaks_id_seq OWNER TO postgres;

--
-- Name: streaks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.streaks_id_seq OWNED BY public.streaks.id;


--
-- Name: submission_comments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.submission_comments (
    id integer NOT NULL,
    submission_id integer NOT NULL,
    user_id integer NOT NULL,
    body text NOT NULL,
    edited_at timestamp without time zone,
    deleted boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    source smallint DEFAULT 1 NOT NULL
);


ALTER TABLE public.submission_comments OWNER TO postgres;

--
-- Name: submission_comments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.submission_comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.submission_comments_id_seq OWNER TO postgres;

--
-- Name: submission_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.submission_comments_id_seq OWNED BY public.submission_comments.id;


--
-- Name: submission_likes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.submission_likes (
    submission_id integer NOT NULL,
    user_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.submission_likes OWNER TO postgres;

--
-- Name: submission_tags; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.submission_tags (
    submission_id integer NOT NULL,
    slug character varying(255) NOT NULL,
    user_id integer
);


ALTER TABLE public.submission_tags OWNER TO postgres;

--
-- Name: submissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.submissions (
    id integer NOT NULL,
    user_id integer NOT NULL,
    title character varying(255),
    description text,
    published boolean DEFAULT true NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    likes_count integer DEFAULT 0 NOT NULL,
    user_rating integer DEFAULT 2 NOT NULL,
    allow_comments boolean DEFAULT true NOT NULL,
    comments_count integer DEFAULT 0 NOT NULL,
    hidden boolean DEFAULT false NOT NULL
);


ALTER TABLE public.submissions OWNER TO postgres;

--
-- Name: submissions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.submissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.submissions_id_seq OWNER TO postgres;

--
-- Name: submissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.submissions_id_seq OWNED BY public.submissions.id;


--
-- Name: uploads; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.uploads (
    id integer NOT NULL,
    user_id integer NOT NULL,
    type integer DEFAULT 0 NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    object_type integer DEFAULT 0,
    object_id integer,
    extension character varying(255) NOT NULL,
    filename character varying(255) NOT NULL,
    size bigint DEFAULT 0 NOT NULL,
    ready boolean DEFAULT false NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    data text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    downloads_count integer DEFAULT 0 NOT NULL,
    storage_type integer DEFAULT 1 NOT NULL,
    width integer,
    height integer
);


ALTER TABLE public.uploads OWNER TO postgres;

--
-- Name: uploads_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.uploads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.uploads_id_seq OWNER TO postgres;

--
-- Name: uploads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.uploads_id_seq OWNED BY public.uploads.id;


--
-- Name: user_ip_addresses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_ip_addresses (
    user_id integer NOT NULL,
    ip character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.user_ip_addresses OWNER TO postgres;

--
-- Name: user_profiles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_profiles (
    user_id integer NOT NULL,
    bio text,
    website text,
    twitter text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    password_reset_token character varying(255)
);


ALTER TABLE public.user_profiles OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id integer NOT NULL,
    username character varying(255) NOT NULL,
    encrypted_password character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    slug character varying(255) NOT NULL,
    last_active timestamp without time zone,
    display_name character varying(255),
    avatar_url character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    submissions_count integer DEFAULT 0 NOT NULL,
    following_count integer DEFAULT 0 NOT NULL,
    followers_count integer DEFAULT 0 NOT NULL,
    streaks_count integer DEFAULT 0 NOT NULL,
    comments_count integer DEFAULT 0 NOT NULL,
    likes_count integer DEFAULT 0 NOT NULL,
    hidden_submissions_count integer DEFAULT 0 NOT NULL,
    hidden_streaks_count integer DEFAULT 0 NOT NULL,
    last_seen_feed_at timestamp without time zone,
    last_timezone character varying(255),
    flags integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: api_keys id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.api_keys ALTER COLUMN id SET DEFAULT nextval('public.api_keys_id_seq'::regclass);


--
-- Name: community_activity_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.community_activity_logs ALTER COLUMN id SET DEFAULT nextval('public.community_activity_logs_id_seq'::regclass);


--
-- Name: community_categories id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.community_categories ALTER COLUMN id SET DEFAULT nextval('public.community_categories_id_seq'::regclass);


--
-- Name: community_category_groups id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.community_category_groups ALTER COLUMN id SET DEFAULT nextval('public.community_category_groups_id_seq'::regclass);


--
-- Name: community_category_tags id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.community_category_tags ALTER COLUMN id SET DEFAULT nextval('public.community_category_tags_id_seq'::regclass);


--
-- Name: community_moderation_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.community_moderation_logs ALTER COLUMN id SET DEFAULT nextval('public.community_moderation_logs_id_seq'::regclass);


--
-- Name: community_pending_posts id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.community_pending_posts ALTER COLUMN id SET DEFAULT nextval('public.community_pending_posts_id_seq'::regclass);


--
-- Name: community_post_edits id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.community_post_edits ALTER COLUMN id SET DEFAULT nextval('public.community_post_edits_id_seq'::regclass);


--
-- Name: community_post_reports id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.community_post_reports ALTER COLUMN id SET DEFAULT nextval('public.community_post_reports_id_seq'::regclass);


--
-- Name: community_posts id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.community_posts ALTER COLUMN id SET DEFAULT nextval('public.community_posts_id_seq'::regclass);


--
-- Name: community_topics id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.community_topics ALTER COLUMN id SET DEFAULT nextval('public.community_topics_id_seq'::regclass);


--
-- Name: exception_requests id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exception_requests ALTER COLUMN id SET DEFAULT nextval('public.exception_requests_id_seq'::regclass);


--
-- Name: exception_types id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exception_types ALTER COLUMN id SET DEFAULT nextval('public.exception_types_id_seq'::regclass);


--
-- Name: notifications id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications ALTER COLUMN id SET DEFAULT nextval('public.notifications_id_seq'::regclass);


--
-- Name: notifications user_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications ALTER COLUMN user_id SET DEFAULT nextval('public.notifications_user_id_seq'::regclass);


--
-- Name: related_streaks id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.related_streaks ALTER COLUMN id SET DEFAULT nextval('public.related_streaks_id_seq'::regclass);


--
-- Name: streaks id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.streaks ALTER COLUMN id SET DEFAULT nextval('public.streaks_id_seq'::regclass);


--
-- Name: submission_comments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.submission_comments ALTER COLUMN id SET DEFAULT nextval('public.submission_comments_id_seq'::regclass);


--
-- Name: submissions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.submissions ALTER COLUMN id SET DEFAULT nextval('public.submissions_id_seq'::regclass);


--
-- Name: uploads id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.uploads ALTER COLUMN id SET DEFAULT nextval('public.uploads_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: api_keys api_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.api_keys
    ADD CONSTRAINT api_keys_pkey PRIMARY KEY (id);


--
-- Name: community_activity_logs community_activity_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.community_activity_logs
    ADD CONSTRAINT community_activity_logs_pkey PRIMARY KEY (id);


--
-- Name: community_bans community_bans_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.community_bans
    ADD CONSTRAINT community_bans_pkey PRIMARY KEY (object_type, object_id, banned_user_id);


--
-- Name: community_blocks community_blocks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.community_blocks
    ADD CONSTRAINT community_blocks_pkey PRIMARY KEY (blocking_user_id, blocked_user_id);


--
-- Name: community_bookmarks community_bookmarks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.community_bookmarks
    ADD CONSTRAINT community_bookmarks_pkey PRIMARY KEY (user_id, object_type, object_id);


--
-- Name: community_categories community_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.community_categories
    ADD CONSTRAINT community_categories_pkey PRIMARY KEY (id);


--
-- Name: community_category_group_categories community_category_group_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.community_category_group_categories
    ADD CONSTRAINT community_category_group_categories_pkey PRIMARY KEY (category_group_id, category_id);


--
-- Name: community_category_groups community_category_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.community_category_groups
    ADD CONSTRAINT community_category_groups_pkey PRIMARY KEY (id);


--
-- Name: community_category_members community_category_members_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.community_category_members
    ADD CONSTRAINT community_category_members_pkey PRIMARY KEY (user_id, category_id);


--
-- Name: community_category_post_logs community_category_post_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.community_category_post_logs
    ADD CONSTRAINT community_category_post_logs_pkey PRIMARY KEY (category_id, post_id);


--
-- Name: community_category_tags community_category_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.community_category_tags
    ADD CONSTRAINT community_category_tags_pkey PRIMARY KEY (id);


--
-- Name: community_moderation_log_objects community_moderation_log_objects_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.community_moderation_log_objects
    ADD CONSTRAINT community_moderation_log_objects_pkey PRIMARY KEY (moderation_log_id, object_type, object_id);


--
-- Name: community_moderation_logs community_moderation_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.community_moderation_logs
    ADD CONSTRAINT community_moderation_logs_pkey PRIMARY KEY (id);


--
-- Name: community_moderators community_moderators_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.community_moderators
    ADD CONSTRAINT community_moderators_pkey PRIMARY KEY (user_id, object_type, object_id);


--
-- Name: community_pending_posts community_pending_posts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.community_pending_posts
    ADD CONSTRAINT community_pending_posts_pkey PRIMARY KEY (id);


--
-- Name: community_post_edits community_post_edits_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.community_post_edits
    ADD CONSTRAINT community_post_edits_pkey PRIMARY KEY (id);


--
-- Name: community_post_reports community_post_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.community_post_reports
    ADD CONSTRAINT community_post_reports_pkey PRIMARY KEY (id);


--
-- Name: community_posts community_posts_moderation_log_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.community_posts
    ADD CONSTRAINT community_posts_moderation_log_id_key UNIQUE (moderation_log_id);


--
-- Name: community_posts community_posts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.community_posts
    ADD CONSTRAINT community_posts_pkey PRIMARY KEY (id);


--
-- Name: community_posts_search community_posts_search_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.community_posts_search
    ADD CONSTRAINT community_posts_search_pkey PRIMARY KEY (post_id);


--
-- Name: community_subscriptions community_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.community_subscriptions
    ADD CONSTRAINT community_subscriptions_pkey PRIMARY KEY (object_type, object_id, user_id);


--
-- Name: community_topic_participants community_topic_participants_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.community_topic_participants
    ADD CONSTRAINT community_topic_participants_pkey PRIMARY KEY (topic_id, user_id);


--
-- Name: community_topics community_topics_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.community_topics
    ADD CONSTRAINT community_topics_pkey PRIMARY KEY (id);


--
-- Name: community_user_category_last_seens community_user_category_last_seens_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.community_user_category_last_seens
    ADD CONSTRAINT community_user_category_last_seens_pkey PRIMARY KEY (user_id, category_id);


--
-- Name: community_user_topic_last_seens community_user_topic_last_seens_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.community_user_topic_last_seens
    ADD CONSTRAINT community_user_topic_last_seens_pkey PRIMARY KEY (user_id, topic_id);


--
-- Name: community_users community_users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.community_users
    ADD CONSTRAINT community_users_pkey PRIMARY KEY (user_id);


--
-- Name: community_votes community_votes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.community_votes
    ADD CONSTRAINT community_votes_pkey PRIMARY KEY (user_id, object_type, object_id);


--
-- Name: daily_audio_plays daily_audio_plays_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.daily_audio_plays
    ADD CONSTRAINT daily_audio_plays_pkey PRIMARY KEY (upload_id, date);


--
-- Name: daily_upload_downloads daily_upload_downloads_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.daily_upload_downloads
    ADD CONSTRAINT daily_upload_downloads_pkey PRIMARY KEY (upload_id, date);


--
-- Name: exception_requests exception_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exception_requests
    ADD CONSTRAINT exception_requests_pkey PRIMARY KEY (id);


--
-- Name: exception_types exception_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exception_types
    ADD CONSTRAINT exception_types_pkey PRIMARY KEY (id);


--
-- Name: featured_streaks featured_streaks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.featured_streaks
    ADD CONSTRAINT featured_streaks_pkey PRIMARY KEY (streak_id);


--
-- Name: featured_submissions featured_submissions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.featured_submissions
    ADD CONSTRAINT featured_submissions_pkey PRIMARY KEY (submission_id);


--
-- Name: followings followings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.followings
    ADD CONSTRAINT followings_pkey PRIMARY KEY (source_user_id, dest_user_id);


--
-- Name: lapis_migrations lapis_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lapis_migrations
    ADD CONSTRAINT lapis_migrations_pkey PRIMARY KEY (name);


--
-- Name: notification_objects notification_objects_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification_objects
    ADD CONSTRAINT notification_objects_pkey PRIMARY KEY (notification_id, object_type, object_id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: related_streaks related_streaks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.related_streaks
    ADD CONSTRAINT related_streaks_pkey PRIMARY KEY (id);


--
-- Name: streak_submissions streak_submissions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.streak_submissions
    ADD CONSTRAINT streak_submissions_pkey PRIMARY KEY (streak_id, submission_id);


--
-- Name: streak_user_notification_settings streak_user_notification_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.streak_user_notification_settings
    ADD CONSTRAINT streak_user_notification_settings_pkey PRIMARY KEY (user_id, streak_id);


--
-- Name: streak_users streak_users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.streak_users
    ADD CONSTRAINT streak_users_pkey PRIMARY KEY (streak_id, user_id);


--
-- Name: streaks streaks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.streaks
    ADD CONSTRAINT streaks_pkey PRIMARY KEY (id);


--
-- Name: submission_comments submission_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.submission_comments
    ADD CONSTRAINT submission_comments_pkey PRIMARY KEY (id);


--
-- Name: submission_likes submission_likes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.submission_likes
    ADD CONSTRAINT submission_likes_pkey PRIMARY KEY (submission_id, user_id);


--
-- Name: submission_tags submission_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.submission_tags
    ADD CONSTRAINT submission_tags_pkey PRIMARY KEY (submission_id, slug);


--
-- Name: submissions submissions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.submissions
    ADD CONSTRAINT submissions_pkey PRIMARY KEY (id);


--
-- Name: uploads uploads_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.uploads
    ADD CONSTRAINT uploads_pkey PRIMARY KEY (id);


--
-- Name: user_ip_addresses user_ip_addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_ip_addresses
    ADD CONSTRAINT user_ip_addresses_pkey PRIMARY KEY (user_id, ip);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: api_keys_key_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX api_keys_key_idx ON public.api_keys USING btree (key);


--
-- Name: api_keys_user_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX api_keys_user_id_idx ON public.api_keys USING btree (user_id);


--
-- Name: community_activity_logs_object_type_object_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX community_activity_logs_object_type_object_id_idx ON public.community_activity_logs USING btree (object_type, object_id);


--
-- Name: community_activity_logs_user_id_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX community_activity_logs_user_id_id_idx ON public.community_activity_logs USING btree (user_id, id);


--
-- Name: community_bans_banned_user_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX community_bans_banned_user_id_idx ON public.community_bans USING btree (banned_user_id);


--
-- Name: community_bans_banning_user_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX community_bans_banning_user_id_idx ON public.community_bans USING btree (banning_user_id);


--
-- Name: community_bans_object_type_object_id_created_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX community_bans_object_type_object_id_created_at_idx ON public.community_bans USING btree (object_type, object_id, created_at);


--
-- Name: community_bookmarks_user_id_created_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX community_bookmarks_user_id_created_at_idx ON public.community_bookmarks USING btree (user_id, created_at);


--
-- Name: community_categories_parent_category_id_position_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX community_categories_parent_category_id_position_idx ON public.community_categories USING btree (parent_category_id, "position") WHERE (parent_category_id IS NOT NULL);


--
-- Name: community_category_group_categories_category_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX community_category_group_categories_category_id_idx ON public.community_category_group_categories USING btree (category_id);


--
-- Name: community_category_members_category_id_user_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX community_category_members_category_id_user_id_idx ON public.community_category_members USING btree (category_id, user_id) WHERE accepted;


--
-- Name: community_category_post_logs_post_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX community_category_post_logs_post_id_idx ON public.community_category_post_logs USING btree (post_id);


--
-- Name: community_category_tags_category_id_slug_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX community_category_tags_category_id_slug_idx ON public.community_category_tags USING btree (category_id, slug);


--
-- Name: community_moderation_logs_category_id_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX community_moderation_logs_category_id_id_idx ON public.community_moderation_logs USING btree (category_id, id) WHERE (category_id IS NOT NULL);


--
-- Name: community_moderation_logs_object_type_object_id_action_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX community_moderation_logs_object_type_object_id_action_id_idx ON public.community_moderation_logs USING btree (object_type, object_id, action, id);


--
-- Name: community_moderation_logs_user_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX community_moderation_logs_user_id_idx ON public.community_moderation_logs USING btree (user_id);


--
-- Name: community_moderators_object_type_object_id_created_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX community_moderators_object_type_object_id_created_at_idx ON public.community_moderators USING btree (object_type, object_id, created_at);


--
-- Name: community_pending_posts_category_id_status_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX community_pending_posts_category_id_status_id_idx ON public.community_pending_posts USING btree (category_id, status, id) WHERE (category_id IS NOT NULL);


--
-- Name: community_pending_posts_topic_id_status_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX community_pending_posts_topic_id_status_id_idx ON public.community_pending_posts USING btree (topic_id, status, id) WHERE (topic_id IS NOT NULL);


--
-- Name: community_post_edits_post_id_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX community_post_edits_post_id_id_idx ON public.community_post_edits USING btree (post_id, id);


--
-- Name: community_post_reports_category_id_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX community_post_reports_category_id_id_idx ON public.community_post_reports USING btree (category_id, id) WHERE (category_id IS NOT NULL);


--
-- Name: community_post_reports_post_id_id_status_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX community_post_reports_post_id_id_status_idx ON public.community_post_reports USING btree (post_id, id, status);


--
-- Name: community_posts_parent_post_id_post_number_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX community_posts_parent_post_id_post_number_idx ON public.community_posts USING btree (parent_post_id, post_number);


--
-- Name: community_posts_parent_post_id_status_post_number_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX community_posts_parent_post_id_status_post_number_idx ON public.community_posts USING btree (parent_post_id, status, post_number);


--
-- Name: community_posts_search_post_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX community_posts_search_post_id_idx ON public.community_posts_search USING btree (post_id);


--
-- Name: community_posts_search_words_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX community_posts_search_words_idx ON public.community_posts_search USING gin (words);


--
-- Name: community_posts_topic_id_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX community_posts_topic_id_id_idx ON public.community_posts USING btree (topic_id, id) WHERE (NOT deleted);


--
-- Name: community_posts_topic_id_parent_post_id_depth_post_number_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX community_posts_topic_id_parent_post_id_depth_post_number_idx ON public.community_posts USING btree (topic_id, parent_post_id, depth, post_number);


--
-- Name: community_posts_topic_id_parent_post_id_depth_status_post_numbe; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX community_posts_topic_id_parent_post_id_depth_status_post_numbe ON public.community_posts USING btree (topic_id, parent_post_id, depth, status, post_number);


--
-- Name: community_posts_user_id_status_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX community_posts_user_id_status_id_idx ON public.community_posts USING btree (user_id, status, id) WHERE (NOT deleted);


--
-- Name: community_subscriptions_user_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX community_subscriptions_user_id_idx ON public.community_subscriptions USING btree (user_id);


--
-- Name: community_topics_category_id_sticky_status_category_order_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX community_topics_category_id_sticky_status_category_order_idx ON public.community_topics USING btree (category_id, sticky, status, category_order) WHERE ((NOT deleted) AND (category_id IS NOT NULL));


--
-- Name: community_user_topic_last_seens_topic_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX community_user_topic_last_seens_topic_id_idx ON public.community_user_topic_last_seens USING btree (topic_id);


--
-- Name: community_votes_object_type_object_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX community_votes_object_type_object_id_idx ON public.community_votes USING btree (object_type, object_id);


--
-- Name: exception_requests_exception_type_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX exception_requests_exception_type_id_idx ON public.exception_requests USING btree (exception_type_id);


--
-- Name: exception_types_label_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX exception_types_label_idx ON public.exception_types USING btree (label);


--
-- Name: featured_streaks_created_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX featured_streaks_created_at_idx ON public.featured_streaks USING btree (created_at);


--
-- Name: featured_streaks_position_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX featured_streaks_position_idx ON public.featured_streaks USING btree ("position");


--
-- Name: followings_dest_user_id_created_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX followings_dest_user_id_created_at_idx ON public.followings USING btree (dest_user_id, created_at);


--
-- Name: followings_dest_user_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX followings_dest_user_id_idx ON public.followings USING btree (dest_user_id);


--
-- Name: followings_source_user_id_created_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX followings_source_user_id_created_at_idx ON public.followings USING btree (source_user_id, created_at);


--
-- Name: notifications_user_id_seen_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX notifications_user_id_seen_id_idx ON public.notifications USING btree (user_id, seen, id);


--
-- Name: notifications_user_id_type_object_type_object_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX notifications_user_id_type_object_type_object_id_idx ON public.notifications USING btree (user_id, type, object_type, object_id) WHERE (NOT seen);


--
-- Name: related_streaks_other_streak_id_type_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX related_streaks_other_streak_id_type_idx ON public.related_streaks USING btree (other_streak_id, type);


--
-- Name: related_streaks_streak_id_type_other_streak_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX related_streaks_streak_id_type_other_streak_id_idx ON public.related_streaks USING btree (streak_id, type, other_streak_id);


--
-- Name: steaks_title_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX steaks_title_idx ON public.streaks USING gin (title public.gin_trgm_ops) WHERE ((NOT deleted) AND (publish_status = 2));


--
-- Name: streak_submissions_streak_id_submit_time_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX streak_submissions_streak_id_submit_time_idx ON public.streak_submissions USING btree (streak_id, submit_time);


--
-- Name: streak_submissions_streak_id_user_id_submit_time_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX streak_submissions_streak_id_user_id_submit_time_idx ON public.streak_submissions USING btree (streak_id, user_id, submit_time);


--
-- Name: streak_submissions_submission_id_streak_id_submit_time_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX streak_submissions_submission_id_streak_id_submit_time_idx ON public.streak_submissions USING btree (submission_id, streak_id, submit_time);


--
-- Name: streak_users_streak_id_created_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX streak_users_streak_id_created_at_idx ON public.streak_users USING btree (streak_id, created_at);


--
-- Name: streak_users_streak_id_pending_created_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX streak_users_streak_id_pending_created_at_idx ON public.streak_users USING btree (streak_id, pending, created_at);


--
-- Name: streak_users_user_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX streak_users_user_id_idx ON public.streak_users USING btree (user_id);


--
-- Name: streaks_publish_status_users_count_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX streaks_publish_status_users_count_idx ON public.streaks USING btree (publish_status, users_count);


--
-- Name: streaks_user_id_publish_status_created_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX streaks_user_id_publish_status_created_at_idx ON public.streaks USING btree (user_id, publish_status, created_at);


--
-- Name: submission_comments_submission_id_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX submission_comments_submission_id_id_idx ON public.submission_comments USING btree (submission_id, id) WHERE (NOT deleted);


--
-- Name: submission_comments_user_id_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX submission_comments_user_id_id_idx ON public.submission_comments USING btree (user_id, id) WHERE (NOT deleted);


--
-- Name: submission_likes_user_id_created_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX submission_likes_user_id_created_at_idx ON public.submission_likes USING btree (user_id, created_at);


--
-- Name: submission_tags_slug_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX submission_tags_slug_idx ON public.submission_tags USING btree (slug);


--
-- Name: submission_tags_user_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX submission_tags_user_id_idx ON public.submission_tags USING btree (user_id);


--
-- Name: submissions_user_id_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX submissions_user_id_id_idx ON public.submissions USING btree (user_id, id);


--
-- Name: submissions_user_id_id_not_hidden_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX submissions_user_id_id_not_hidden_idx ON public.submissions USING btree (user_id, id) WHERE (NOT hidden);


--
-- Name: submissions_user_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX submissions_user_id_idx ON public.submissions USING btree (user_id);


--
-- Name: uploads_object_type_object_id_position_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX uploads_object_type_object_id_position_idx ON public.uploads USING btree (object_type, object_id, "position") WHERE ready;


--
-- Name: uploads_user_id_type_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX uploads_user_id_type_idx ON public.uploads USING btree (user_id, type);


--
-- Name: user_ip_addresses_ip_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_ip_addresses_ip_idx ON public.user_ip_addresses USING btree (ip);


--
-- Name: user_profiles_password_reset_token_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_profiles_password_reset_token_idx ON public.user_profiles USING btree (password_reset_token) WHERE (password_reset_token IS NOT NULL);


--
-- Name: users_lower_email_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX users_lower_email_idx ON public.users USING btree (lower((email)::text));


--
-- Name: users_lower_username_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX users_lower_username_idx ON public.users USING btree (lower((username)::text));


--
-- Name: users_slug_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX users_slug_idx ON public.users USING btree (slug);


--
-- Name: users_username_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX users_username_idx ON public.users USING gin (username public.gin_trgm_ops);


--
-- PostgreSQL database dump complete
--

--
-- PostgreSQL database dump
--

-- Dumped from database version 12.1
-- Dumped by pg_dump version 12.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: lapis_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.lapis_migrations (name) FROM stdin;
1418544084
1419494897
1419752545
1420172340
1420172477
1420172985
1420176500
1420176501
1420181212
1420363626
1420405517
1420424459
1420431193
1420433528
1420437606
1420444339
1420449446
1420710737
1420712611
1421223602
1421473626
1421473830
1421477232
1422135963
1422142380
1422162067
1422163531
1422165197
1422174951
1422177586
1422262875
1422337369
1422383477
1422606062
1422641893
1422731265
1423123029
1423209193
1423678535
1423712362
1425376265
1425545586
1425941245
1426401405
1426439394
1427955442
1431573586
1431917444
1431922768
1431928525
1432002497
1432009672
1432010515
1432190692
1432794242
1433905410
1443740672
1443753807
1443853745
1444151912
1445927662
1454140126
1454396365
community_1
community_2
community_3
community_4
community_5
community_6
community_7
community_8
community_9
community_10
community_11
community_12
community_13
1477634820
1477809405
community_14
community_15
community_16
community_17
1483430549
community_18
community_19
1484032396
community_20
community_21
community_22
community_23
1510810389
1516221126
community_24
community_25
community_26
1524276008
1566456125
1580505725
community_27
community_28
1580506174
1580928124
1580928125
1580932859
1581023628
\.


--
-- PostgreSQL database dump complete
--

