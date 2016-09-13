# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron
#
# Learn more: http://github.com/javan/whenever

# on servers, we need path to the right Ruby interpreter
env :PATH, ENV['PATH']

# make sure to run through bundle
job_type :runner, "cd :path && bin/bundle exec rails runner -e :environment ':task' :output"

every 30.minutes do
  runner 'FeedFetcherService.fetch_some_ready_feeds_async'
end

every 1.day, at: '12:01 am' do
  runner 'Stop.re_conflate_with_osm'
  rake 'feed:maintenance:extend_expired_feed_versions_cron'
  rake 'feed:maintenance:enqueue_next_feed_versions_cron'
end
