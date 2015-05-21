
class S.Stats
  constructor: (el, @opts) ->
    @el = $ el
    graphs = @opts.graphs

    console.log @opts

    if @opts.cumulative
      grapher = S.CumulativeGrapher
      prefix = "Cumulative"
    else
      throw new Error "not yet"


    new grapher "#users_graph", graphs.users, {
      label: "#{prefix} users"
    }

    new grapher "#submissions_graph", graphs.submissions, {
      label: "#{prefix} submissions"
    }

    new grapher "#submission_comments_graph", graphs.submission_comments, {
      label: "#{prefix} comments"
    }

    new grapher "#submission_likes_graph", graphs.submission_likes, {
      label: "#{prefix} likes"
    }

    new grapher "#streaks_graph", graphs.streaks, {
      label: "#{prefix} streaks"
    }

