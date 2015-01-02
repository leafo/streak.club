
import escape from require "lapis.util"
import assert_error from require "lapis.application"

config = require("lapis.config").get!
cookie_name = "#{config.session_name}_token"

csrf = require "lapis.csrf"

math.randomseed os.time!
import random from math

generate_key = do
  random_char = ->
    switch random 1,3
      when 1
        random 65, 90
      when 2
        random 97, 122
      when 3
        random 48, 57

  (length) ->
    string.char unpack [ random_char! for i=1,length ]

generate_csrf = =>
  token = @cookies[cookie_name]
  unless token
    token = "#{generate_key 15}_STREAK-BUTT_#{generate_key 15}"
    @res\add_header "Set-cookie", "#{cookie_name}=#{escape token}; Path=/; HttpOnly"

  @csrf_token = csrf.generate_token @, token

check_csrf = =>
  token = @cookies[cookie_name]
  return nil, "no token" unless token
  csrf.validate_token @, token

assert_csrf = =>
  assert_error check_csrf(@), "invalid csrf"

{ :generate_csrf, :check_csrf, :assert_csrf }
