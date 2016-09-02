task :feed_extend_schedule, [:feed_onestop_id, :extend_from_date, :extend_to_date] => [:environment] do |t, args|
  feed = Feed.find_by_onestop_id!(args.feed_onestop_id)
  feed_version = feed.active_feed_version
  extend_from_date = args.extend_from_date || (feed_version.latest_calendar_date - 1.month)
  extend_to_date = args.extend_from_date || (feed_version.latest_calendar_date + 1.year)
  ssp_total = feed_version.imported_schedule_stop_pairs.count
  ssp_updated = feed_version.imported_schedule_stop_pairs.where('service_end_date >= ?', extend_from_date).count
  puts "Feed: #{feed.onestop_id}"
  puts "  active_feed_version: #{feed_version.sha1}"
  puts "    earliest_calendar_date: #{feed_version.earliest_calendar_date}"
  puts "    latest_calendar_date: #{feed_version.latest_calendar_date}"
  puts "    ssp total: #{ssp_total}"
  puts "  extending:"
  puts "    extend_from_date: #{extend_from_date}"
  puts "    extend_to_date: #{extend_to_date}"
  puts "    ssp to update: #{ssp_updated}"
  feed_version.extend_schedule_stop_pairs_service_end_date(extend_from_date, extend_to_date)
end
