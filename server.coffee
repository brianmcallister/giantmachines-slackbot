request = require 'request-promise'
schedule = require 'node-schedule'
Slack = require 'slack-client'
moment = require 'moment'
express = require 'express'

app = express();
server = app.listen process.env.PORT or 3000, () ->
  console.log 'listening on port', server.address().port

require('dotenv').load()

apiHost = 'https://slack.com/api'
apiToken = process.env.SLACK_API_TOKEN

pp = (thing) ->
  console.log JSON.stringify thing, null, 2

# Build up timestamps for the Harvest api.
timesheetStartDay = moment().day('Monday').date()
timesheetEndDay = moment().day('Friday').date()
timesheetRange = [timesheetStartDay..timesheetEndDay]
fromTimesheetTimestamp = moment().day('Monday').format 'YYYYMMDD'
toTimesheetTimestamp = moment().day('Friday').format 'YYYYMMDD'

# Create the Slack client.
slack = new Slack apiToken, true, true

console.log 'connected to Harvest as', process.env.HARVEST_EMAIL

# Start a scheduled job.
# TODO: Need a better way to say 'run this on friday evening'. Just parse date
# every whatever interval?
# job = schedule.scheduleJob '* * * * *', ->

getHarvestUsers = ->
  request
    url: "https://#{process.env.HARVEST_SUBDOMAIN}.harvestapp.com/people"
    auth:
      user: process.env.HARVEST_EMAIL
      pass: process.env.HARVEST_PASSWORD
    headers:
      'Accept': 'application/json'
      'Content-Type': 'application/json'

parseUsers = (response) ->
  response = JSON.parse response
  (user.user for user in response when user.user.is_active)

getWeeklyTimesheets = (users) ->
  requests = users.map (user) ->
    request
      url: "https://#{process.env.HARVEST_SUBDOMAIN}.harvestapp.com/people/#{user.id}/entries"
      qs:
        from: fromTimesheetTimestamp
        to: toTimesheetTimestamp
      auth:
        user: process.env.HARVEST_EMAIL
        pass: process.env.HARVEST_PASSWORD
      headers:
        'Accept': 'application/json'
        'Content-Type': 'application/json'
    .then (timesheet) ->
      user: user
      timesheet: JSON.parse timesheet

  Promise.all(requests)

parseWeeklyTimesheets = (timesheets) ->
  caughtUsers = []

  timesheets.forEach (timesheet) ->
    spentDays = []
    missingDays = []

    for day in timesheet.timesheet
      spentDay = moment(day.day_entry.spent_at).date()

      if spentDays.indexOf(spentDay) is -1
        spentDays.push spentDay

    if timesheetRange.length isnt spentDays.length
      for day in timesheetRange
        if spentDays.indexOf(day) is -1
          missingDays.push day

      caughtUsers.push
        user: timesheet.user
        missingDays: missingDays

  caughtUsers

notifyDelinquentUsers = (delinquents) ->
  console.log 'notify', delinquents

getHarvestUsers()
  .then(parseUsers)
  .then(getWeeklyTimesheets)
  .then(parseWeeklyTimesheets)
  .then(notifyDelinquentUsers)
  .then ->
    console.log 'done'

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
