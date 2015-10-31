# Only load .env when in development.
if process.env.NODE_ENV isnt 'production'
  require('dotenv').load()
  
module.exports =
  slackApiHost: 'https://slack.com/api'
  slackApiToken: process.env.SLACK_API_TOKEN

  harvestSubdomain: process.env.HARVEST_SUBDOMAIN
  harvestEmail: process.env.HARVEST_EMAIL
  harvestPassword: process.env.HARVEST_PASSWORD
