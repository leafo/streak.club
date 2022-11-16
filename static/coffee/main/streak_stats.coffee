
import {CumulativeGrapher} from "main/graph"
import $ from "main/jquery"

export class StreakStats
  constructor: (el, opts) ->
    @el = $ el
    graphs = opts.graphs

    new CumulativeGrapher "#users_graph", graphs.cumulative_users, {
      label: "Total participants"
      min_y: 10
    }


    new CumulativeGrapher "#submissions_graph", graphs.cumulative_submissions, {
      label: "Total submissions"
      min_y: 10
    }
