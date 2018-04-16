csrf = require "lapis.csrf"

{
  generate_csrf: csrf.generate_token
  assert_csrf: csrf.assert_token
}
