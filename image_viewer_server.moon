
server = require "resty.websocket.server"

wb, err = server\new {
  timeout = 5000,  -- in milliseconds
  max_payload_len = 65535,
}

unless wb
  ngx.log ngx.ERR, "failed to create websocket server: ", err
  return ngx.exit 444

data, typ, err = wb\recv_frame()

require("moon").p {
  :data, :typ
}
