db = require "lapis.db"
import Model from require "lapis.db.model"

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE user_ip_addresses (
--   user_id integer NOT NULL,
--   ip character varying(255) NOT NULL,
--   created_at timestamp without time zone NOT NULL,
--   updated_at timestamp without time zone NOT NULL
-- );
-- ALTER TABLE ONLY user_ip_addresses
--   ADD CONSTRAINT user_ip_addresses_pkey PRIMARY KEY (user_id, ip);
-- CREATE INDEX user_ip_addresses_ip_idx ON user_ip_addresses USING btree (ip);
--
class UserIpAddresses extends Model
  @timestamp: true
  @primary_key: {"user_id", "ip"}

  @register_ip: (r) =>
    return unless r.current_user
    ip = r.req.headers['x-original-ip'] or ngx.var.remote_addr

    current = @find user_id: r.current_user.id, ip: ip
    return if current
    pcall ->
      @create user_id: r.current_user.id, ip: ip

