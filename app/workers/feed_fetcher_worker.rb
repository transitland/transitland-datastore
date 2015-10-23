class FeedFetcherWorker
  include Sidekiq::Worker

  sidekiq_options unique: true,
                  unique_job_expiration: 60 * 60 # 1 hour

  def perform(feed_onestop_id)
    begin
      feed = Feed.find_by_onestop_id!(feed_onestop_id)
      logger.info "FeedFetcherWorker checking #{feed.onestop_id}"
      feed_version = feed.fetch_and_return_feed_version
      logger.info "FeedFetcherWorker checked #{feed.onestop_id} and found sha1: #{feed_version.sha1}"
    rescue Exception => e
      # NOTE: we're catching all exceptions, including Interrupt,
      #   SignalException, and SyntaxError
      logger.error e.message
      logger.error e.backtrace
      Raven.capture_exception(e) if defined?(Raven)
    end
  end
end
