task :enqueue_next_feed_version, [:date] => [:environment] do |t, args|
  date = Date.parse(args.date)
  Feed.find_each do |feed|
    # Check for active_feed_version
    active_feed_version = feed.active_feed_version
    next unless active_feed_version
    # Find the most recently created feed_version that will have service
    # on (date) and is newer than the active_feed_version.
    next_feed_version = feed
      .feed_versions
      .where('earliest_calendar_date > ?', active_feed_version.earliest_calendar_date)
      .where('earliest_calendar_date <= ?', date)
      .reorder(earliest_calendar_date: :desc, created_at: :desc)
      .first
    next unless next_feed_version
    # Check for any previous import
    next if next_feed_version.feed_version_imports.last
    # Enqueue
    import_level = feed.active_feed_version.import_level || 2
    puts "Feed: #{feed.onestop_id}"
    puts "  active_feed_version sha1: #{active_feed_version.sha1}"
    puts "  active_feed_version date: #{active_feed_version.earliest_calendar_date} - #{active_feed_version.latest_calendar_date}"
    puts "  next_feed_version   sha1: #{next_feed_version.sha1}"
    puts "  next_feed_version   date: #{next_feed_version.earliest_calendar_date} - #{next_feed_version.latest_calendar_date}"
    worker_id = FeedEaterWorker.perform_async(
      feed.onestop_id,
      next_feed_version.sha1,
      import_level
    )
    if worker_id
      puts "  FeedEaterWorker #{worker_id} enqueued"
    else
      puts "  FeedEaterWorker: Could not enqueue"
    end
  end
end
