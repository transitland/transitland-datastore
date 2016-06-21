task :enqueue_next_feed_version, [:date] => [:environment] do |t, args|
  date = Date.parse(args.date)
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
