
class S.StreakStats
  constructor: (el, opts) ->
    @el = $ el
    graphs = opts.graphs

    new S.CumulativeGrapher "#users_graph", graphs.cumulative_users, {
      label: "Total participants"
      min_y: 10
    }


    new S.CumulativeGrapher "#submissions_graph", graphs.cumulative_submissions, {
      label: "Total submissions"
      min_y: 10
    }
