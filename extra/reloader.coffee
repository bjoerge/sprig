# Used by server
serve = (opts={host: undefined, port: 8081}) ->
  WebSocketServer = require('ws').Server
  wss = new WebSocketServer(opts)
  clients = []

  wss.on 'connection', (client) ->
    clients.push client
    console.log("Client connected, got #{clients.length} clients in total.")

    client.on 'close', ->
      index = clients.indexOf(client)

      clients.splice(index, 1) if index != -1

      console.log("Client disconnected. Got #{clients.length} left")

  wss.on 'error', (client) ->
    console.log("Error: ", client)

  console.log("Waiting for connections");

  ->
    (try client.send('reload')) for client in clients

# Used by client
connect = (opts={}) ->
  # if user is running mozilla then use it's built-in WebSocket
  window.WebSocket ||= window.MozWebSocket

  connection = new WebSocket('ws://' + (opts.host || document.domain || 'localhost') + ':'+(opts.port || 8081))

  connection.onopen = ->
    console.log("Connected to watcher")

  connection.onerror = ->
    console.log("Unable to connect to watcher")
 
  connection.onmessage = (message) ->
    window.location.reload() if (message.data == 'reload')

exports.serve = serve
exports.connect = connect