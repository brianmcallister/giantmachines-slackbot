prettyjson = require 'prettyjson'

# Wrap prettyjson to always log.
module.exports = (value) ->
  console.log prettyjson.render value
