--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: exception_requests; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE exception_requests (
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

CREATE SEQUENCE exception_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.exception_requests_id_seq OWNER TO postgres;

--
-- Name: exception_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE exception_requests_id_seq OWNED BY exception_requests.id;


--
-- Name: exception_types; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE exception_types (
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

CREATE SEQUENCE exception_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.exception_types_id_seq OWNER TO postgres;

--
-- Name: exception_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE exception_types_id_seq OWNED BY exception_types.id;


--
-- Name: featured_streaks; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE featured_streaks (
    streak_id integer NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.featured_streaks OWNER TO postgres;

--
-- Name: followings; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE followings (
    source_user_id integer NOT NULL,
    dest_user_id integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.followings OWNER TO postgres;

--
-- Name: lapis_migrations; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE lapis_migrations (
    name character varying(255) NOT NULL
);


ALTER TABLE public.lapis_migrations OWNER TO postgres;

--
-- Name: notification_objects; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE notification_objects (
    notification_id integer NOT NULL,
    object_type integer DEFAULT 0 NOT NULL,
    object_id integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.notification_objects OWNER TO postgres;

--
-- Name: notifications; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE notifications (
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

CREATE SEQUENCE notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.notifications_id_seq OWNER TO postgres;

--
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE notifications_id_seq OWNED BY notifications.id;


--
-- Name: notifications_user_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE notifications_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.notifications_user_id_seq OWNER TO postgres;

--
-- Name: notifications_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE notifications_user_id_seq OWNED BY notifications.user_id;


--
-- Name: streak_submissions; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE streak_submissions (
    streak_id integer NOT NULL,
    submission_id integer NOT NULL,
    submit_time timestamp without time zone NOT NULL,
    user_id integer NOT NULL,
    late_submit boolean DEFAULT false NOT NULL
);


ALTER TABLE public.streak_submissions OWNER TO postgres;

--
-- Name: streak_users; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE streak_users (
    streak_id integer NOT NULL,
    user_id integer NOT NULL,
    submissions_count integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.streak_users OWNER TO postgres;

--
-- Name: streaks; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE streaks (
    id integer NOT NULL,
    user_id integer NOT NULL,
    title character varying(255) NOT NULL,
    short_description text NOT NULL,
    description text NOT NULL,
    published boolean DEFAULT false NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    rate integer DEFAULT 0 NOT NULL,
    users_count integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    submissions_count integer DEFAULT 0 NOT NULL,
    hour_offset integer DEFAULT 0 NOT NULL,
    publish_status integer NOT NULL,
    category integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.streaks OWNER TO postgres;

--
-- Name: streaks_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE streaks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.streaks_id_seq OWNER TO postgres;

--
-- Name: streaks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE streaks_id_seq OWNED BY streaks.id;


--
-- Name: submission_comments; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE submission_comments (
    id integer NOT NULL,
    submission_id integer NOT NULL,
    user_id integer NOT NULL,
    body text NOT NULL,
    edited_at timestamp without time zone,
    deleted boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.submission_comments OWNER TO postgres;

--
-- Name: submission_comments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE submission_comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.submission_comments_id_seq OWNER TO postgres;

--
-- Name: submission_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE submission_comments_id_seq OWNED BY submission_comments.id;


--
-- Name: submission_likes; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE submission_likes (
    submission_id integer NOT NULL,
    user_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.submission_likes OWNER TO postgres;

--
-- Name: submission_tags; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE submission_tags (
    submission_id integer NOT NULL,
    slug character varying(255) NOT NULL
);


ALTER TABLE public.submission_tags OWNER TO postgres;

--
-- Name: submissions; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE submissions (
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
    comments_count integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.submissions OWNER TO postgres;

--
-- Name: submissions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE submissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.submissions_id_seq OWNER TO postgres;

--
-- Name: submissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE submissions_id_seq OWNED BY submissions.id;


--
-- Name: uploads; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE uploads (
    id integer NOT NULL,
    user_id integer NOT NULL,
    type integer DEFAULT 0 NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    object_type integer DEFAULT 0,
    object_id integer,
    extension character varying(255) NOT NULL,
    filename character varying(255) NOT NULL,
    size integer DEFAULT 0 NOT NULL,
    ready boolean DEFAULT false NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    data text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.uploads OWNER TO postgres;

--
-- Name: uploads_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE uploads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.uploads_id_seq OWNER TO postgres;

--
-- Name: uploads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE uploads_id_seq OWNED BY uploads.id;


--
-- Name: user_profiles; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE user_profiles (
    user_id integer NOT NULL,
    bio text,
    website text,
    twitter text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.user_profiles OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE users (
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
    admin boolean DEFAULT false NOT NULL,
    streaks_count integer DEFAULT 0 NOT NULL,
    comments_count integer DEFAULT 0 NOT NULL,
    likes_count integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY exception_requests ALTER COLUMN id SET DEFAULT nextval('exception_requests_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY exception_types ALTER COLUMN id SET DEFAULT nextval('exception_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY notifications ALTER COLUMN id SET DEFAULT nextval('notifications_id_seq'::regclass);


--
-- Name: user_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY notifications ALTER COLUMN user_id SET DEFAULT nextval('notifications_user_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY streaks ALTER COLUMN id SET DEFAULT nextval('streaks_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY submission_comments ALTER COLUMN id SET DEFAULT nextval('submission_comments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY submissions ALTER COLUMN id SET DEFAULT nextval('submissions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY uploads ALTER COLUMN id SET DEFAULT nextval('uploads_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: exception_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY exception_requests
    ADD CONSTRAINT exception_requests_pkey PRIMARY KEY (id);


--
-- Name: exception_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY exception_types
    ADD CONSTRAINT exception_types_pkey PRIMARY KEY (id);


--
-- Name: featured_streaks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY featured_streaks
    ADD CONSTRAINT featured_streaks_pkey PRIMARY KEY (streak_id);


--
-- Name: followings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY followings
    ADD CONSTRAINT followings_pkey PRIMARY KEY (source_user_id, dest_user_id);


--
-- Name: lapis_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY lapis_migrations
    ADD CONSTRAINT lapis_migrations_pkey PRIMARY KEY (name);


--
-- Name: notification_objects_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY notification_objects
    ADD CONSTRAINT notification_objects_pkey PRIMARY KEY (notification_id, object_type, object_id);


--
-- Name: notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: streak_submissions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY streak_submissions
    ADD CONSTRAINT streak_submissions_pkey PRIMARY KEY (streak_id, submission_id);


--
-- Name: streak_users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY streak_users
    ADD CONSTRAINT streak_users_pkey PRIMARY KEY (streak_id, user_id);


--
-- Name: streaks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY streaks
    ADD CONSTRAINT streaks_pkey PRIMARY KEY (id);


--
-- Name: submission_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY submission_comments
    ADD CONSTRAINT submission_comments_pkey PRIMARY KEY (id);


--
-- Name: submission_likes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY submission_likes
    ADD CONSTRAINT submission_likes_pkey PRIMARY KEY (submission_id, user_id);


--
-- Name: submission_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY submission_tags
    ADD CONSTRAINT submission_tags_pkey PRIMARY KEY (submission_id, slug);


--
-- Name: submissions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY submissions
    ADD CONSTRAINT submissions_pkey PRIMARY KEY (id);


--
-- Name: uploads_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY uploads
    ADD CONSTRAINT uploads_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: exception_requests_exception_type_id_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX exception_requests_exception_type_id_idx ON exception_requests USING btree (exception_type_id);


--
-- Name: exception_types_label_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX exception_types_label_idx ON exception_types USING btree (label);


--
-- Name: featured_streaks_position_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE UNIQUE INDEX featured_streaks_position_idx ON featured_streaks USING btree ("position");


--
-- Name: followings_dest_user_id_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX followings_dest_user_id_idx ON followings USING btree (dest_user_id);


--
-- Name: notifications_user_id_seen_id_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX notifications_user_id_seen_id_idx ON notifications USING btree (user_id, seen, id);


--
-- Name: notifications_user_id_type_object_type_object_id_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE UNIQUE INDEX notifications_user_id_type_object_type_object_id_idx ON notifications USING btree (user_id, type, object_type, object_id) WHERE (NOT seen);


--
-- Name: streak_submissions_streak_id_submit_time_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX streak_submissions_streak_id_submit_time_idx ON streak_submissions USING btree (streak_id, submit_time);


--
-- Name: streak_submissions_streak_id_user_id_submit_time_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX streak_submissions_streak_id_user_id_submit_time_idx ON streak_submissions USING btree (streak_id, user_id, submit_time);


--
-- Name: streak_submissions_submission_id_streak_id_submit_time_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX streak_submissions_submission_id_streak_id_submit_time_idx ON streak_submissions USING btree (submission_id, streak_id, submit_time);


--
-- Name: streak_users_user_id_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX streak_users_user_id_idx ON streak_users USING btree (user_id);


--
-- Name: submission_comments_submission_id_id_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX submission_comments_submission_id_id_idx ON submission_comments USING btree (submission_id, id) WHERE (NOT deleted);


--
-- Name: submission_comments_user_id_id_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX submission_comments_user_id_id_idx ON submission_comments USING btree (user_id, id) WHERE (NOT deleted);


--
-- Name: submission_likes_user_id_created_at_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX submission_likes_user_id_created_at_idx ON submission_likes USING btree (user_id, created_at);


--
-- Name: submission_tags_slug_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX submission_tags_slug_idx ON submission_tags USING btree (slug);


--
-- Name: submissions_user_id_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX submissions_user_id_idx ON submissions USING btree (user_id);


--
-- Name: uploads_object_type_object_id_position_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX uploads_object_type_object_id_position_idx ON uploads USING btree (object_type, object_id, "position") WHERE ready;


--
-- Name: uploads_user_id_type_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX uploads_user_id_type_idx ON uploads USING btree (user_id, type);


--
-- Name: users_lower_email_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE UNIQUE INDEX users_lower_email_idx ON users USING btree (lower((email)::text));


--
-- Name: users_lower_username_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE UNIQUE INDEX users_lower_username_idx ON users USING btree (lower((username)::text));


--
-- Name: users_slug_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE UNIQUE INDEX users_slug_idx ON users USING btree (slug);


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = public, pg_catalog;

--
-- Data for Name: lapis_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY lapis_migrations (name) FROM stdin;
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
\.


--
-- PostgreSQL database dump complete
--

