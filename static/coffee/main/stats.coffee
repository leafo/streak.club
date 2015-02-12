
class S.Stats
  constructor: (el, @opts) ->
    @el = $ el
    graphs = opts.graphs

    new S.CumulativeGrapher "#users_graph", graphs.cumulative_users, {
      label: "Cumulative users"
    }
