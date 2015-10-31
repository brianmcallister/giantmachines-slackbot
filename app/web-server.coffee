http = require 'http'

module.exports.start = (port) ->
  http.createServer (req, res) ->
    res.end ''
  .listen process.env.PORT or 3000

  console.log 'Listening on', process.env.PORT or 3000
