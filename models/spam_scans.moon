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
    spam: 1
    ham: 2
  }

  @review_statuses: enum {
    default: 1
    needs_review: 2
    reviewed: 3
  }

  @status_for_score: (score) =>
    if socre and score > 0.6
      "needs_review"
    else
      "default"

  @user_texts: (user) =>
    if user._spam_scans_user_texts
      return user._spam_scans_user_texts

    texts = {
      user.username
      user.display_name
    }

    add_text = (text) ->
      if text
        table.insert texts, text

    profile = user\get_user_profile!

    add_text profile\format_website!
    add_text profile.bio

    import Streaks, Submissions from require "models"
    for streak in *Streaks\select "where user_id = ? order by id asc limit 10", user.id
      add_text streak.title
      add_text streak.short_description
      add_text streak.description

    for submission in *Submissions\select "where user_id = ? order by id asc limit 10", user.id
      add_text submission.title
      add_text submission.description

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
    -- [ ] recaptcha result score (note if recaptcha is not available)
    -- [ ] register referrer
    -- [*] browser time zone (last time zone only set on streak creation)
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

    if next tokens
      tokens

  @tokenize_user_text: (user) =>
    text_tokenizer\tokenize_text table.concat @user_texts(user), "\n"

  @refresh_for_user: (user) =>
    @bayes_categories! -- to ensure that they exist

    user_tokens = @tokenize_user user
    text_tokens = @tokenize_user_text user

    score = nil

    if user_tokens
      C = require "lapis.bayes.classifiers.bayes"
      classifier = C { max_words: 1000 }
      res, err = classifier\text_probabilities {"user.spam", "user.ham"}, user_tokens
      score = res

    if text_tokens
      C = require "lapis.bayes.classifiers.bayes"
      classifier = C { max_words: 1000 }
      res, err = classifier\text_probabilities {"text.spam", "text.ham"}, text_tokens
      if res and res > score or 0
        score = res

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
        review_status: @review_statuses\for_db @status_for_score score
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

  @create: (opts) =>
    opts.train_status = @train_statuses\for_db opts.train_status or "untrained"
    opts.review_status = @review_statuses\for_db opts.review_status or "default"

    if opts.user_tokens
      opts.user_tokens = db.array opts.user_tokens

    if opts.text_tokens
      opts.text_tokens = db.array opts.text_tokens

    insert_on_conflict_ignore @, opts

  -- refresh the tokens and rescore
  rescan: =>
    error "not yet"



