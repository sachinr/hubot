# Continuously searches Twitter for mentions of a specified string.

module.exports = (robot) ->
  cronJob = require('cron').CronJob
  response = new robot.Response(robot)
  query = process.env.TWITTER_MENTION_QUERY

  if query?
    new cronJob '*/1 * * * *', ->
      last_tweet = robot.brain.data.last_tweet
      last_tweet_id = if last_tweet then last_tweet.id_str else ''
      response.http('http://search.twitter.com/search.json')
        .query(q: escape(query), since_id: last_tweet_id)
        .get() (err, res, body) ->
          tweets = JSON.parse(body)
          if tweets.results? and tweets.results.length > 0
            for tweet in tweets.results.reverse()
              robot.adapter.send '', "#{tweet.from_user_name} tweeted #{tweet.text}"
              robot.adapter.send '', "http://twitter.com/#!/#{tweet.from_user}/status/#{tweet.id_str}"
              robot.brain.data.last_tweet = tweet
    , null, true
  else
    robot.adapter.send '', 'No Query string provided'
