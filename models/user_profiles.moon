db = require "lapis.db"
import Model from require "lapis.db.model"

class UserProfiles extends Model
  @primary_key: {"user_id"}
  @timestamp: true

  -- without @
  twitter_handle: =>
    return unless @twitter
    @twitter\match("twitter.com/([^/]+)") or @twitter\match("^@(.+)") or @twitter

  format_website: =>
    return unless @website
    return @website if @website\match "^(%w+)://"
    "http://" .. @website
