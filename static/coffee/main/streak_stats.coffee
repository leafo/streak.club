
import $ from "main/jquery"

export class StreakStats
  constructor: (el, @opts) ->
    @el = $ el

  render: ->
    {CumulativeGrapher} = await import("/static/graphs.esm.min.js")

    {graphs} = @opts

    new CumulativeGrapher "#users_graph", graphs.cumulative_users, {
      label: "Total participants"
      min_y: 10
    }


    new CumulativeGrapher "#submissions_graph", graphs.cumulative_submissions, {
      label: "Total submissions"
      min_y: 10
    }
