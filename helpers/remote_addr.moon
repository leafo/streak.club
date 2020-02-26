->
  return unless ngx
  ip = ngx.var.remote_addr
  if ip == "127.0.0.1"
    ngx.var.http_x_original_ip or ip
  else
    ip
