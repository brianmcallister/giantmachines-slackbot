HarvestClient = require './harvest-client'
moment = require 'moment'

pp = require './pretty-print'

module.exports = class TimesheetReportGenerator
  # Build up timestamps for the Harvest api.
  monday = moment().endOf('week').day 'Monday'
  friday = moment().endOf('week').day 'Friday'
  timesheetRange = [monday.date()..friday.date()]
  fromTimesheetTimestamp = monday.format 'YYYYMMDD'
  toTimesheetTimestamp = friday.format 'YYYYMMDD'

  constructor: (config) ->
    @harvest = new HarvestClient config.harvestConfig

  generate: ->
    @harvest.people()
      .then(filterUsers)
      .then(getWeeklyTimesheets.bind(this))
      .then(parseWeeklyTimesheets)
      .then(generateReport)

  filterUsers = (users) ->
    (user.user for user in users when user.user.is_active)

  getWeeklyTimesheets = (users) ->
    query =
      qs:
        from: fromTimesheetTimestamp
        to: toTimesheetTimestamp

    requests = users.map (user) =>
      @harvest.peopleTimesheetEntries(user.id, query).then (timesheet) ->
        user: user
        timesheet: timesheet

    Promise.all requests

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

  generateReport = (users) ->
    users
