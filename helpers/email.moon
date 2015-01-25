
ltn12 = require "ltn12"

http = require "lapis.nginx.http"
import encode_query_string from require "lapis.util"
import encode_base64 from require "lapis.util.encoding"

import concat from table

config = require("lapis.config").get!

{:sender, :api_url, :key} = config.email

assert sender, "missing sender from config"
assert api_url, "missing mailgun api url"
assert key, "missing mailgun api key"

json = require "cjson"

api_request = (path, data, prefix=api_url) ->
  out = {}
  res = http.request {
    url: prefix .. path
    source: data and ltn12.source.string(encode_query_string data) or nil
    headers: {
      "Content-type": "application/x-www-form-urlencoded"
      "Authorization": "Basic " .. encode_base64 "api:#{key}"
    }
    sink: ltn12.sink.table out
  }

  concat(out), res

add_recipients = (data, field, emails) ->
  return unless emails

  if type(emails) == "table"
    for email in *emails
      table.insert data, {field, email}
  else
    data[field] = emails

send_email = (to, subject, body, opts={}) ->
  return if config.disable_email

  data = {
    from: opts.sender or sender
    subject: subject
    [opts.html and "html" or "text"]: body
  }

  add_recipients data, "to", to
  add_recipients data, "cc", opts.cc
  add_recipients data, "bcc", opts.bcc

  if opts.tags
    for t in *opts.tags
      table.insert data, {"o:tag", t}

  if opts.vars
    data["recipient-variables"] = json.encode opts.vars

  if opts.headers
    for h, v in pairs opts.headers
      data["h:#{h}"] = v

  if opts.track_opens
    data["o:tracking-opens"] = "yes"

  if c = opts.campaign
    data["o:campaign"] = c

  api_request "/messages", data

create_campaign = (name) ->
  res = api_request "/campaigns", { :name }
  res = json.decode res
  res.campaign

get_campaigns = ->
  res = api_request "/campaigns"
  res = json.decode res
  res.items


get_messages = ->
  params = encode_query_string {
    event: "stored"
  }
  json.decode (api_request "/events?#{params}")

get_or_create_campaign_id = (campaign_name) ->
  local campaign_id

  for c in *get_campaigns!
    if c.name == campaign_name
      campaign_id = c.id
      break

  unless campaign_id
    campaign_id = create_campaign(campaign_name).id

  campaign_id

{ :send_email, :create_campaign, :get_campaigns, :get_messages,
  :get_or_create_campaign_id }
