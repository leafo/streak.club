
render_submissions_page = (per_page) =>
  assert @submissions, "missing submissions"

  SubmissionList = require "widgets.submission_list_bare"
  widget = SubmissionList!
  widget\include_helper @

  json: {
    success: true
    page: @page
    submissions_count: #@submissions
    has_more: #@submissions == per_page
    rendered: widget\render_to_string!
  }


{ :render_submissions_page }
