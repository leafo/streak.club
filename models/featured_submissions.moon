db = require "lapis.db"
import Model, preload from require "lapis.db.model"
import safe_insert from require "helpers.model"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE featured_submissions (
--   submission_id integer NOT NULL,
--   created_at timestamp without time zone NOT NULL,
--   updated_at timestamp without time zone NOT NULL
-- );
-- ALTER TABLE ONLY featured_submissions
--   ADD CONSTRAINT featured_submissions_pkey PRIMARY KEY (submission_id);
--
class FeaturedSubmissions extends Model
  @primary_key: "submission_id"
  @timestamp: true

  @relations: {
    {"submission", belongs_to: "Submissions"}
  }

  @find_submissions: (per_page=25) =>
    @paginated "order by created_at desc", {
      :per_page
      prepare_results: (featured) ->
        import Submissions from require "models"
        preload featured, "submission"
        submissions = [f\get_submission! for f in *featured]
        Submissions\preload_for_list submissions

        [s for s in *submissions when not s.deleted]
    }


