# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron
#
# Learn more: http://github.com/javan/whenever

job_type :runner, "cd :path && bin/bundle exec rails runner -e :environment ':task' :output"

every 1.day, at: '12:01 pm' do
  runner 'Feed.async_fetch_all_feeds'
end

every 1.day, at: '12:01 am' do
  runner 'Stop.re_conflate_with_osm'
end
