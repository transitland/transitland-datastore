task :extend_feed_version, [:feed_onestop_id, :extend_from_date, :extend_to_date] => [:environment] do |t, args|
  args.with_defaults(expired_from_date: nil)
  args.with_defaults(expired_to_date: nil)
  feed = Feed.find_by_onestop_id!(args.feed_onestop_id)
  FeedMaintenanceService.extend_feed_version(
    feed.active_feed_version,
    extend_from_date: args.extend_from_date,
    extend_to_date: args.extend_to_date
  )
end

task :extend_expired_feed_versions, [:expired_on_date] => [:environment] do |t, args|
  args.with_defaults(expired_on_date: nil)
  FeedMaintenanceService.extend_expired_feed_versions(args.expired_on_date)
end
