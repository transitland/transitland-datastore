task :feed_extend_schedule, [:feed_onestop_id, :extend_from_date, :extend_to_date] => [:environment] do |t, args|
  args.with_defaults(expired_from_date: nil)
  args.with_defaults(expired_to_date: nil)
  feed = Feed.find_by_onestop_id!(args.feed_onestop_id)
  FeedMaintenanceService.extend_feed_version(
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
    FeedMaintenanceService.extend_feed_version(feed_version)
  end
end
