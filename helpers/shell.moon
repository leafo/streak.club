
shell_quote = (str) ->
  escaped = str\gsub "'", [['"'"']]
  "'#{escaped}'"

exec = (cmd) ->
  os.execute cmd

{ :shell_quote, :exec }
