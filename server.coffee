pp = require './app/pretty-print'
config = require './config/config'
schedule = require 'node-schedule'
Slack = require 'slack-client'
TimesheetReportGenerator = require './app/timesheet-report-generator'
moment = require 'moment'

# We need to bind to the port provided by Heroku within 60 seconds,
# or else the app will crash and restart in a loop forever.
require('./app/web-server').start process.env.PORT or 3000

setInterval ->
  pp moment().date()
  
  # Check if today is Friday.
  if moment().date() is moment().endOf('week').day('Friday').date()
    pp 'friday'

, 1000# * 60 * 60

return

generator = new TimesheetReportGenerator
  harvestConfig:
    subdomain: config.harvestSubdomain
    email: config.harvestEmail
    password: config.harvestPassword

generator.generate().then (report) ->
  pp report
return

# Create the Slack client.
slack = new Slack apiToken, true, true

slack.on 'open', ->
  console.log 'connected to', slack.team.name, 'as', slack.self.name

slack.on 'message', (message) ->
  # Get a list of Harvest users.

  # Get list of users.
  req = getUsers()

  req.then (res) ->
    res = JSON.parse res
    printUserReport res.members

  req.catch (res) ->
    console.log 'error', res

slack.on 'error', (error) ->
  console.error 'error', error

slack.login()


getUsers = ->
  request url: "#{apiHost}/users.list", qs: token: apiToken

printUserReport = (slackUsers) ->
  users = []

  for user in slackUsers
    # We only care about gathering up user's emails here.
    # Ignore some users.
    if user.deleted or user.is_bot or user.is_restricted or user.is_ultra_restricted
      continue

    users.push user.profile.email

  pp users
