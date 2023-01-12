
import $ from "main/jquery"

export class Stats
  constructor: (el, @opts) ->
    @el = $ el
    @render()

  render: (el) ->
    {CumulativeGrapher, RangeGrapher} = await import("/static/graphs.esm.min.js")

    graphs = @opts.graphs

    if @opts.cumulative
      grapher = CumulativeGrapher
      prefix = "Cumulative"
      gopts = {}
    else
      grapher = RangeGrapher
      prefix = "Daily"
      gopts = { no_dots: true, x_ticks: 8 }

    new grapher "#users_graph", graphs.users, $.extend {
      label: "#{prefix} registrations"
    }, gopts

    new grapher "#submissions_graph", graphs.submissions, $.extend {
      label: "#{prefix} submissions"
    }, gopts

    new grapher "#submission_comments_graph", graphs.submission_comments, $.extend {
      label: "#{prefix} comments"
    }, gopts

    new grapher "#submission_likes_graph", graphs.submission_likes, $.extend {
      label: "#{prefix} likes"
    }, gopts

    new grapher "#streaks_graph", graphs.streaks, $.extend {
      label: "#{prefix} streaks"
    }, gopts

