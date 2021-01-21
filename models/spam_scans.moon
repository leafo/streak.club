db = require "lapis.db"
import Model, enum from require "lapis.db.model"

-- NOTE: when we convert everything to markdown internally we will need to
-- ensure this can still detect URLs correctly

import insert_on_conflict_ignore, db_json from require "helpers.model"

import Categories, WordClassifications from require "lapis.bayes.models"
UrlDomainsTokenizer = require "lapis.bayes.tokenizers.url_domains"
PostgresTextTokenizer = require "lapis.bayes.tokenizers.postgres_text"

bayes = require "lapis.bayes"

normalize_gmail = (email) ->
  left, right = email\match "([^@]+)@(.+)"

  left = left\gsub "%.", ""
  left = left\gsub "%+.+$", ""
  left, right

tokenize_email = (email, insert) ->
  return unless email
  email = email\lower!

  email_left, email_right = email\match "^(.-)@(.+)$"
  if email_left
    insert "e.#{email}"
    insert "el.#{email_left}"
    insert "er.#{email_right}"

    gmail_l, gmail_r = normalize_gmail email

    if gmail_r == "gmail.com" and gmail_l != email_left
      insert "elg.#{gmail_l}"

  else
    insert "invalid_email"

ignore_tokens = {
  "er.gmail.com": true
  "er.yahoo.com": true
}

domain_tokenizer = UrlDomainsTokenizer {
  ignore_domains: enum {
    "*.bp.blogspot.com"
    "*.gfycat.com"
    "*.google.com"
    "*.postimg.com"
    "*.postimg.org"
    "*.tinypic.com"
    "*.wp.com"
    "bit.ly"
    "facebook.com"
    "gist.github.com"
    "goo.gl"
    "google.com"
    "i.gyazo.com"
    "i.imgur.com"
    "reddit.com"
    "tinyurl.com"
    "twitter.com"
    "youtu.be"
    "youtube.com"
    "linkedin.com"
    "en.wikipedia.org"
    "streak.club"
  }
}

text_tokenizer = PostgresTextTokenizer {}

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE spam_scans (
--   id integer NOT NULL,
--   user_id integer NOT NULL,
--   train_status smallint DEFAULT 1 NOT NULL,
--   review_status smallint DEFAULT 1 NOT NULL,
--   user_tokens text[],
--   text_tokens text[],
--   score numeric,
--   created_at timestamp without time zone NOT NULL,
--   updated_at timestamp without time zone NOT NULL
-- );
-- ALTER TABLE ONLY spam_scans
--   ADD CONSTRAINT spam_scans_pkey PRIMARY KEY (id);
-- CREATE UNIQUE INDEX spam_scans_user_id_idx ON spam_scans USING btree (user_id);
--
class SpamScans extends Model
  @timestamp: true

  @relations: {
    {"user", belongs_to: "Users"}
  }

  @bayes_categories = =>
    {
      user_spam: Categories\find_or_create "user.spam"
      user_ham: Categories\find_or_create "user.ham"

      text_spam: Categories\find_or_create "text.spam"
      text_ham: Categories\find_or_create "text.ham"
    }

  @train_statuses: enum {
    untrained: 1
    spam: 2
    ham: 3
  }

  @review_statuses: enum {
    default: 1
    needs_review: 2
    reviewed: 3
  }

  @status_for_score: (score) =>
    if score and score > 0.6
      "needs_review"
    else
      "default"

  -- this returns an array of HTML chunks (so we can get domains out of the text)
  -- when training as plain text, concat and extract the text first
  @user_texts: (user) =>
    if user._spam_scans_user_texts
      return user._spam_scans_user_texts

    texts = {
      user.username
      user.display_name
    }

    -- we convert text -> html so we can treat the entire output as html
    add_text = (text) ->
      import escape from require "lapis.html"
      if text
        table.insert texts, escape text

    add_html = (html) ->
      if html
        table.insert texts, html

    profile = user\get_user_profile!

    add_text profile\format_website!
    add_html profile.bio

    import Streaks, Submissions from require "models"
    for streak in *Streaks\select "where user_id = ? order by id asc limit 10", user.id
      add_text streak.title
      add_text streak.short_description
      add_html streak.description

    for submission in *Submissions\select "where user_id = ? order by id asc limit 10", user.id
      add_text submission.title
      add_html submission.description

    user._spam_scans_user_texts = texts
    texts

  @tokenize_user: (user) =>
    -- some of this data we do not collect yet
    -- [*] ip addresses
    -- [*] asnum
    -- [*] email, email left, email right, normalized email
    -- [*] any domains in profile, recent submissions, streak descriptions (will have to be extended to all text at some point: forum posts, comments)
    -- [ ] register email bounce (we don't even sent a register email right now)
    -- [*] country code
    -- [ ] quickly created something
    -- [ ] quickly set profile
    -- [*] recaptcha result score (note if recaptcha is not available)
    -- [ ] register referrer
    -- [*] browser time zone (last time zone is set async on layout render when logged in)
    -- [ ] browser user agent
    -- [ ] accept lang
    tokens = {}
    insert = (t) ->
      return unless t
      return if ignore_tokens[t]

      for existing in *tokens
        if existing == t
          return

      table.insert tokens, t

    import ip_to_asnum_short, ip_to_country_code from require "helpers.geo"

    for ip in *user\get_ip_addresses!
      insert "ip.#{ip.ip}"
      if asnum = ip_to_asnum_short ip.ip
        insert "an.#{asnum}"

      if country = ip_to_country_code ip.ip
        insert "c.#{country}"

    tokenize_email user.email, insert

    if user.last_timezone
      insert "tz.#{user.last_timezone}"

    domains = domain_tokenizer\tokenize_text table.concat @user_texts(user), "\n"
    if domains
      for d in *domains
        insert "d.#{d}"

    if rr = user\get_register_captcha_result!
      if score = rr.data.score
        centered = (score*100 - 50)

        for i=0,-50,-10
          if centered <= i
            insert "rc.#{i}"

        for i=0,50,10
          if centered >= i
            insert "rc.#{i}"
      else
        insert "rc.missing"

    if next tokens
      tokens

  @tokenize_user_text: (user) =>
    html = table.concat @user_texts(user), "\n"
    import extract_text from require "helpers.html"
    text = extract_text html
    text_tokenizer\tokenize_text text

  @summarize_tokens: (tokens, categories) =>
    category_models = @bayes_categories!

    category_ids = [assert(category_models[c], "invalid category: #{c}").id for c in *categories]

    -- convert to objects to hold the preloaded counts
    tokens = [{:token} for token in *tokens]

    WordClassifications\include_in tokens, "word", {
      flip: true
      many: true
      where: {
        category_id: db.list category_ids
      }
      as: "counts"
      local_key: "token"
    }

    cbyid = {category_models[c].id, category_models[c] for c in *categories}

    for t in *tokens
      sum = 0
      for word in *t.counts
        word.category = cbyid[word.category_id]
        sum += word.count

      for word in *t.counts
        word.p = word.count / sum

      table.sort t.counts, (a, b) ->
        (a.p or 0) > (b.p or 0)

    tokens

  -- returns the spam score
  @score_user_tokens: (tokens) =>
    C = require "lapis.bayes.classifiers.bayes"
    classifier = C { max_words: 1000 }
    res, err = classifier\text_probabilities {"user.spam", "user.ham"}, tokens

    unless res
      return nil, err

    if res and res["user.spam"]
      res["user.spam"]

  -- returns the spam score
  @score_text_tokens: (tokens) =>
    C = require "lapis.bayes.classifiers.bayes"
    classifier = C { max_words: 1000 }
    res, err = classifier\text_probabilities {"text.spam", "text.ham"}, tokens

    unless res
      return nil, err

    if res and res["text.spam"]
      res["text.spam"]

  @refresh_for_user: (user) =>
    @bayes_categories! -- to ensure that they exist

    user_tokens = @tokenize_user user
    text_tokens = @tokenize_user_text user

    score = nil

    if user_tokens
      score = @score_user_tokens user_tokens

    if text_tokens
      s = @score_text_tokens text_tokens
      if s and s > (score or 0)
        score = s

    scan = @create {
      user_id: user.id
      :user_tokens
      :text_tokens
      :score
      review_status: @status_for_score score
    }

    unless scan
      -- try to update it
      scan = @find user_id: user.id
      db.update @table_name!, {
        score: score or db.NULL
        review_status: unless scan\is_reviewed!
          @review_statuses\for_db @status_for_score score
        user_tokens: if next user_tokens
          db.array user_tokens
        else
          db.NULL

        text_tokens: if next text_tokens
          db.array text_tokens
        else
          db.NULL

        updated_at: db.format_date!
      }, {
        user_id: user.id
        train_status: @train_statuses.untrained
      }
      scan\refresh!

    scan

  @create: (opts) =>
    opts.train_status = @train_statuses\for_db opts.train_status or "untrained"
    opts.review_status = @review_statuses\for_db opts.review_status or "default"

    if opts.user_tokens and next opts.user_tokens
      opts.user_tokens = db.array opts.user_tokens
    else
      opts.user_tokens = nil

    if opts.text_tokens and next opts.text_tokens
      opts.text_tokens = db.array opts.text_tokens
    else
      opts.text_tokens = nil

    insert_on_conflict_ignore @, opts

  -- refresh the tokens and rescore
  rescan: =>
    error "not yet"

  needs_review: =>
    not @is_trained! and @review_status == @@review_statuses.needs_review

  is_trained: =>
    @train_status != @@train_statuses.untrained

  is_reviewed: =>
    @review_status == @@review_statuses.reviewed

  mark_reviewed: =>
    return nil, "already reviewed" if @is_reviewed!

    -- get a lock on the update by only updating it when loaded fields match
    res = db.update @@table_name!, {
      review_status: @@review_statuses.reviewed
    }, {
      id: assert @id
      review_status: @review_status
      train_status: @train_status
    }

    if res and res.affected_rows > 0
      @refresh!
      true

  train: (status) =>
    train_status = @@train_statuses\for_db status

    if @is_trained!
      return nil, "already trained, can't train again"

    import transition from require "helpers.model"
    if transition @, "train_status", @@train_statuses.untrained, train_status

      categories = @@bayes_categories!

      for category, tokens in pairs {
        [categories["user_#{status}"]]: @user_tokens
        [categories["text_#{status}"]]: @text_tokens
      }
        continue unless next tokens

        counts = {}
        for t in *tokens
          counts[t] or= 0
          counts[t] += 1

        category\increment_words counts

      @update {
        review_status: @@review_statuses.reviewed
      }

      true
    else
      nil, "failed to get lock on spam object to train"

  admin_url_params: (r, ...) =>
    "admin.spam_queue", nil, { user_id: @user_id }

  untrain: =>
    error "TODO"



