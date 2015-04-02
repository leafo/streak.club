db = require "lapis.db"
import Model from require "lapis.db.model"
import safe_insert from require "helpers.model"

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

        Submissions\include_in featured, "submission_id"
        submissions = [f.submission for f in *featured]
        Submissions\preload_for_list submissions

        [s for s in *submissions when not s.deleted]
    }


