request = require 'request-promise'

_ = require 'underscore'
pp = require './pretty-print'

# HarvestClient class.
module.exports = class HarvestClient
  defaultRequestOpts = {}

  constructor: (opts = {}) ->
    @apiHost = "https://#{opts.subdomain}.harvestapp.com"
    @email = opts.email
    @password = opts.password

    defaultRequestOpts =
      url: @apiHost
      auth:
        user: @email
        pass: @password
      headers:
        'Accept': 'application/json'
        'Content-Type': 'application/json'

    console.log 'Connected to Harvest as', @email

  people: ->
    makeRequest 'people'

  peopleTimesheetEntries: (userId, options) ->
    makeRequest "people/#{userId}/entries", options

  makeRequest = (endpoint, options = {}) ->
    opts = _.extend {}, defaultRequestOpts, options
    opts.url += "/#{endpoint}"
    request(opts).then (res) -> JSON.parse res
