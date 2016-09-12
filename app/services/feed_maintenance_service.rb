class FeedMaintenanceService
  include Singleton

  def self.extend_feed_version(feed_version, extend_from_date: nil, extend_to_date: nil)
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

  private

end
