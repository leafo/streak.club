
import validate_signed_url from require "helpers.url"

params = ngx.req.get_uri_args!

is_valid = validate_signed_url {
  req: {
    parsed_url: {
      path: ngx.var.uri
    }
  }
  params: params
}

unless is_valid
  return ngx.exit ngx.HTTP_FORBIDDEN

if ngx.now! > tonumber params.expires
  return ngx.exit ngx.HTTP_GONE
