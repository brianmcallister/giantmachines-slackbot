express = require 'express'
app = express()

app.set 'port', process.env.PORT or 3000

app.get '/', (req, res) ->
  res.send 'hello'

server = app.listen app.get('port'), ->
  addr = server.address()
  console.log 'listening at http://%s:%s', addr.host or 'localhost', addr.port
