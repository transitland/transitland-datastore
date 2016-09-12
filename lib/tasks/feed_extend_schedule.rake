def extend_feed_version(feed_version, extend_from_date: nil, extend_to_date: nil)
  feed = feed_version.feed
  previously_extended = (feed_version.tags || {})["extend_from_date"]
  extend_from_date ||= (feed_version.latest_calendar_date - 1.month)
  extend_to_date ||= (feed_version.latest_calendar_date + 1.year)
  ssp_total = feed_version.imported_schedule_stop_pairs.count
  ssp_updated = feed_version.imported_schedule_stop_pairs.where('service_end_date >= ?', extend_from_date).count
  puts "Feed: #{feed.onestop_id}"
  puts "  active_feed_version: #{feed_version.sha1}"
  puts "    latest_calendar_date: #{feed_version.latest_calendar_date}"
  puts "    ssp total: #{ssp_total}"
  if previously_extended
    puts "  already extended, skipping:"
    puts "    extend_from_date: #{feed_version.tags['extend_from_date']}"
    puts "    extend_to_date: #{feed_version.tags['extend_to_date']}"
  else
    puts "  extending:"
    puts "    extend_from_date: #{extend_from_date}"
    puts "    extend_to_date: #{extend_to_date}"
    puts "    ssp to update: #{ssp_updated}"
    feed_version.extend_schedule_stop_pairs_service_end_date(extend_from_date, extend_to_date)
  end
end

task :feed_extend_schedule, [:feed_onestop_id, :extend_from_date, :extend_to_date] => [:environment] do |t, args|
  feed = Feed.find_by_onestop_id!(args.feed_onestop_id)
  extend_feed_version(
    feed.active_feed_version,
    extend_from_date: args.extend_from_date,
    extend_to_date: args.extend_to_date
  )
end

task :feed_extend_schedule_auto, [:expired_on_date] => [:environment] do |t, args|
  args.with_defaults(expired_on_date: nil)
  expired_on_date = args.expired_on_date ? Date.parse(args.expired_on_date) : (DateTime.now + 1.week)
  feed_versions = FeedVersion.where_active.where('latest_calendar_date <= ?', expired_on_date)
  feed_versions.each do |feed_version|
    extend_feed_version(feed_version)
  end
end
