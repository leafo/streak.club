P = R.package "ImageViewer"

P "Client", {

  componentDidMount: ->
    console.log "server url", @props.server_url
    @connection = new WebSocket @props.server_url

    @connection.addEventListener "open", (event) =>
      console.log "open", event
      # @connection.send "Hello world"
    
    @connection.addEventListener "message", (event) =>
      console.log "message from server", event.data

    @connection.addEventListener "error", (event) =>
      console.log "error from server", event

    @connection.addEventListener "close", (event) =>
      console.log "server closed"

  componentWillUnmount: ->
    console.log "unmounting, disconnecting"
    @connection.close()
    delete @connection

  render: ->
    div {}, "Hello world from future websocket client"
}
