
class ReminderEmail extends require "emails.email"
  @needs: {"email_subject", "email_body"}

  subject: => "#{assert @email_subject, "missing subject for email"} - Streak Club"

  body: =>
    h1 @email_subject
    div class: "user_formatted", ->
      raw assert @email_body, "missing body for email"

