
class S.Stats
  constructor: (el, @opts) ->
    @el = $ el
    graphs = @opts.graphs

    new S.CumulativeGrapher "#users_graph", graphs.cumulative_users, {
      label: "Cumulative users"
    }

    new S.CumulativeGrapher "#submissions_graph", graphs.cumulative_submissions, {
      label: "Cumulative submissions"
    }

    new S.CumulativeGrapher "#submission_comments_graph", graphs.cumulative_submission_comments, {
      label: "Cumulative comments"
    }

    new S.CumulativeGrapher "#submission_likes_graph", graphs.cumulative_submission_likes, {
      label: "Cumulative likes"
    }

    new S.CumulativeGrapher "#streaks_graph", graphs.cumulative_streaks, {
      label: "Cumulative streaks"
    }

