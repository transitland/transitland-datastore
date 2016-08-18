task :enqueue_feed_fetcher_workers, [] => [:environment] do |t, args|
  begin
    workers = FeedFetcherService.fetch_all_feeds_async
    if workers
      puts "FeedEaterWorkers #{workers} created and enqueued."
    else
      raise 'FeedEaterWorker could not be created or enqueued.'
    end
  rescue
    puts "Error: #{$!.message}"
    puts $!.backtrace
  end
end

task :enqueue_feed_eater_worker, [:feed_onestop_id, :feed_version_sha1, :import_level] => [:environment] do |t, args|
  begin
    import_level = (args.import_level || 0).to_i # default import level
    feed_eater_worker = FeedEaterWorker.perform_async(args.feed_onestop_id, args.feed_version_sha1, import_level)
    if feed_eater_worker
      puts "FeedEaterWorker ##{feed_eater_worker} has been created and enqueued."
    else
      raise 'FeedEaterWorker could not be created or enqueued.'
    end
  rescue
    puts "Error: #{$!.message}"
    puts $!.backtrace
  end
end

task :enqueue_next_feed_versions, [:date] => [:environment] do |t, args|
  args.with_defaults(date: nil)
  date = args.date ? Date.parse(args.date) : DateTime.now
  Feed.find_each do |feed|
    worker_id = feed.enqueue_next_feed_version(date)
    if worker_id
      puts "#{feed.onestop_id}: worker #{worker_id} enqueued"
      active_feed_version = feed.active_feed_version
      next_feed_version = feed.find_next_feed_version(date)
      puts "  active #{active_feed_version.sha1}"
      puts "    calendar  : #{active_feed_version.earliest_calendar_date} - #{active_feed_version.latest_calendar_date}"
      puts "    created_at: #{active_feed_version.created_at}"
      puts "  next   #{next_feed_version.sha1}"
      puts "    calendar  : #{next_feed_version.earliest_calendar_date} - #{next_feed_version.latest_calendar_date}"
      puts "    created_at: #{next_feed_version.created_at}"
    else
      puts "#{feed.onestop_id}: no update"
    end
  end
end
