assert = require "luassert"

local last_email

stubbed_req = {
  url_for: (url) =>
    -- the whole app isn't loaded so we don't have routes available
    if type(url) == "table"
      url = url.__class.__name

    "[[#{url}]]"

  build_url: (...) => ...
}

stub_email_module = (callback) ->
  package.loaded["helpers.email"] = {
    send_email: (...) ->
      send_opts = {...}
      callback and callback send_opts
      nil

    get_or_create_campaign_id: (name) -> "[[#{name}]]"
  }

  stubbed_req

stub_email = ->
  busted = require "busted"

  busted.before_each ->
    last_email = {}
    stub_email_module (send_opts) ->
      table.insert last_email, send_opts
      busted.publish {"lapis", "html"}, send_opts[3], title: "test"

  busted.after_each ->
    package.loaded["helpers.email"] = nil

  (-> unpack last_email), stubbed_req

assert_email_sent = (email, check_opts={html: true}) ->
  assert #last_email == 1, "expected 1 email to be sent, got #{#last_email}"
  send_opts = unpack last_email

  assert send_opts, "expected email to be sent"
  if email != nil
    if type(email) == "table"
      table.sort email

      sent_email = if type(send_opts[1]) == "table"
        send_opts[1]
      else
        {send_opts[1]}

      table.sort sent_email
      assert.same email, sent_email
    else
      assert.same email, send_opts[1]

  for k,v in pairs check_opts
    assert.same v, send_opts[4][k]

assert_emails_sent = (emails, check_opts={html: true}) ->
  sent_emails = [ send[1] for send in *last_email ]
  table.sort sent_emails
  expected = [e for e in *emails]
  table.sort expected
  assert.same expected, sent_emails

  for k,v in pairs check_opts
    for send in *last_email
      assert.same v, send[4][k]

{ :stub_email, :assert_email_sent, :assert_emails_sent, :stub_email_module }

