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
  FeedMaintenanceService.extend_expired_feed_versions(expired_on_date: args.expired_on_date)
end

task :extend_expired_feed_versions_cron, [] => [:environment] do |t, args|
  if Figaro.env.extend_expired_feed_versions.presence == 'true'
    FeedMaintenanceService.extend_expired_feed_versions
  end
end

task :enqueue_next_feed_versions, [:date] => [:environment] do |t, args|
  args.with_defaults(date: nil)
  date = args.date ? Date.parse(args.date) : DateTime.now
  FeedMaintenanceService.enqueue_next_feed_versions(date)
end

task :enqueue_next_feed_versions_cron, [] => [:environment] do |t, args|
  date = DateTime.now
  max_imports = (Figaro.env.enqueue_next_feed_versions_max.presence || 0).to_i
  if max_imports > 0
    FeedMaintenanceService.enqueue_next_feed_versions(date, max_imports: max_imports)
  end
end
