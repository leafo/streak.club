
config = require("lapis.config").get!

import Mailgun from require "mailgun"
mailgun = Mailgun config.mailgun

send_email = (to, subject, body, opts={}) ->
  if config.dump_email
    print "Sending email:"
    require("moon").p {
      :to, :subject, :body, :opts
    }

  return if config.disable_email

  send = { :to, :subject, :body }
  send[k] = v for k,v in pairs opts

  mailgun\send_email send

{ :send_email }
