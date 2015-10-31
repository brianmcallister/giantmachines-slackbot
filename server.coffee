express = require 'express'
app = express()

app.get '/', (req, res) ->
  res.send 'hello'

server = app.listen 3000, ->
  addr = server.address()
  console.log 'listening at http://%s:%s', addr.host or 'localhost', addr.port
