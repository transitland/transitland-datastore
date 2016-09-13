class FeedMaintenanceService
  include Singleton

  DEFAULT_EXTEND_FROM_DATE = 1.month
  DEFAULT_EXTEND_TO_DATE = 1.year
  DEFAULT_EXPIRED_ON_DATE = 1.week

  def self.logger
    Rails.logger
  end

  def self.extend_expired_feed_versions(expired_on_date)
    expired_on_date ||= (DateTime.now + DEFAULT_EXPIRED_ON_DATE)
    feed_versions = FeedVersion.where_active.where('latest_calendar_date <= ?', expired_on_date)
    feed_versions.each do |feed_version|
      self.extend_feed_version(feed_version)
    end
  end

  def self.extend_feed_version(feed_version, extend_from_date: nil, extend_to_date: nil)
    feed = feed_version.feed
    previously_extended = (feed_version.tags || {})["extend_from_date"]
    extend_from_date ||= (feed_version.latest_calendar_date - DEFAULT_EXTEND_FROM_DATE)
    extend_to_date ||= (feed_version.latest_calendar_date + DEFAULT_EXTEND_TO_DATE)
    ssp_total = feed_version.imported_schedule_stop_pairs.count
    ssp_updated = feed_version.imported_schedule_stop_pairs.where('service_end_date >= ?', extend_from_date).count
    logger.info "Feed: #{feed.onestop_id}"
    logger.info "  active_feed_version: #{feed_version.sha1}"
    logger.info "    latest_calendar_date: #{feed_version.latest_calendar_date}"
    logger.info "    ssp total: #{ssp_total}"
    if previously_extended
      logger.info "  already extended, skipping:"
      logger.info "    extend_from_date: #{feed_version.tags['extend_from_date']}"
      logger.info "    extend_to_date: #{feed_version.tags['extend_to_date']}"
    else
      logger.info "  extending:"
      logger.info "    extend_from_date: #{extend_from_date}"
      logger.info "    extend_to_date: #{extend_to_date}"
      logger.info "    ssp to update: #{ssp_updated}"
      feed_version.extend_schedule_stop_pairs_service_end_date(extend_from_date, extend_to_date)
    end
  end

  private

end
