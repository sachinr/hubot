# Description:
#   Continuously searches Twitter for mentions of a specified string.
#
# Commands:
#   hubot set twitter query <search_term> - Set search query
#   hubot show twitter query - Show current search query
#
# Dependencies:
#   "cron": "1.0.1"
#
# Configuration:
#   HUBOT_TWITTER_MENTION_QUERY
#   HUBOT_TWITTER_MENTION_ROOM
#
# Author:
#   Sachinr

module.exports = (robot) ->
  cronJob  = require('cron').CronJob
  response = new robot.Response(robot)
  robot.brain.data.twitter_mention ?= {}

  if twitter_query(robot)?
    new cronJob '*/5 * * * *', ->
      last_tweet = robot.brain.data.twitter_mention.last_tweet || ''

      response.http('http://search.twitter.com/search.json')
        .query(q: escape(twitter_query(robot)), since_id: last_tweet)
        .get() (err, res, body) ->
          tweets = JSON.parse(body)
          if tweets.results? and tweets.results.length > 0
            robot.brain.data.twitter_mention.last_tweet = tweets.results[0].id_str
            for tweet in tweets.results.reverse()
              sendMessage robot, "http://twitter.com/#!/#{tweet.from_user}/status/#{tweet.id_str}"

    , null, true
  else
    sendMessage robot, 'No query string configured in the environment'

  robot.respond /(set twitter query) (.*)/i, (msg) ->
    robot.brain.data.twitter_mention.query = msg.match[2]
    robot.brain.data.twitter_mention.last_tweet = ''
    msg.send "I'm now searching Twitter for: #{twitter_query(robot)}"

  robot.respond /(show twitter query)/i, (msg) ->
    msg.send "I'm searching Twitter for: #{twitter_query(robot)}"

twitter_query = (robot) ->
  robot.brain.data.twitter_mention.query ||
    process.env.HUBOT_TWITTER_MENTION_QUERY

sendMessage = (robot, str) ->
  robot.adapter.send({room: process.env.HUBOT_TWITTER_MENTION_ROOM}, str )
