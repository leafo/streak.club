remote_addr = require "helpers.remote_addr"

geoip = require "geoip.mmdb"

asnum_db = geoip.load_database "/var/lib/GeoIP/GeoLite2-ASN.mmdb"
country_db = geoip.load_database "/var/lib/GeoIP/GeoLite2-Country.mmdb"

with M = {}
  -- this returns the number and name to match old geoip library
  .ip_to_asnum = (ip) ->
    if res = asnum_db and asnum_db\lookup ip
      "AS#{res.autonomous_system_number} #{res.autonomous_system_organization}"

  .ip_to_asnum_short = (ip) ->
    if res = asnum_db and asnum_db\lookup ip
      "AS#{res.autonomous_system_number}"

  .ip_to_country_code = (ip) ->
    if country_db
      if c = country_db\lookup_value ip, "country", "iso_code"
        return c

      -- some proxy services don't have a country but a registered_country
      if c = country_db\lookup_value ip, "registered_country", "iso_code"
        return c

      -- default to the content
      if c = country_db\lookup_value ip, "continent", "code"
        return c

  -- lets us override implementation for references to current_country
  ._current_country = ->
    if ip = remote_addr!
      .ip_to_country_code ip

  .current_country = -> ._current_country!

  ._current_asnum = ->
    if ip = remote_addr!
      .ip_to_asnum ip

  .current_asnum = -> ._current_asnum!

