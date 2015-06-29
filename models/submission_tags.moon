db = require "lapis.db"
import Model from require "lapis.db.model"

import concat from table
import from_json from require "lapis.util"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE submission_tags (
--   submission_id integer NOT NULL,
--   slug character varying(255) NOT NULL,
--   user_id integer
-- );
-- ALTER TABLE ONLY submission_tags
--   ADD CONSTRAINT submission_tags_pkey PRIMARY KEY (submission_id, slug);
-- CREATE INDEX submission_tags_slug_idx ON submission_tags USING btree (slug);
-- CREATE INDEX submission_tags_user_id_idx ON submission_tags USING btree (user_id);
--
class SubmissionTags extends Model
  @max_tags_per_item: 10
  @primary_key: {"submission_id", "slug"}

  tag_parser = do
    lpeg = require "lpeg"
    import R, S, V, P from lpeg
    import C, Cs, Ct, Cmt, Cg, Cb, Cc from lpeg

    flatten_words = (words) -> concat words, " "

    sep = P","
    space = S" \t\r\n"
    white = space^0
    word = C (1 - (space + sep))^1
    words = Ct((word * white)^1) / flatten_words

    white * Ct (words^-1 * white * sep * white)^0 * words^-1 * -1

  @parse: (str) =>
    if "[" == str\sub 1,1
      tags = from_json str
      tags = [t for t in *tags when type(t) == "string"]
      [t for t in *tags[,@max_tags_per_item]]
    else
      tag_parser\match(str) or {}

  @slugify: (str) =>
    str = str\gsub "%s+", "-"
    str = str\gsub "[^%w%-_%.]+", ""
    str = str\gsub "^[%-%._]+", ""
    str = str\gsub "[%-%._]+$", ""
    str = str\lower!
    str

  @create: (opts={}) =>
    assert opts.slug
    assert opts.submission_id
    assert opts.user_id

    opts.slug = @slugify opts.slug
    Model.create @, opts

