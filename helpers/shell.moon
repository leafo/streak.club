
shell_escape = (str) ->
  str\gsub "'", [['"'"']]

exec = (cmd) ->
  os.execute cmd

{ :shell_escape, :exec }
