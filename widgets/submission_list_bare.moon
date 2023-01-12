-- this is used by xhr to fetch a page of submission results
class SubmissionList extends require "widgets.submission_list"
  @es_module: false

  content: =>
    @render_submissions!

