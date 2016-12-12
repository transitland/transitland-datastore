class FeedFetcherWorker
  include Sidekiq::Worker

  sidekiq_options unique: :until_and_while_executing,
                  unique_job_expiration: 60 * 60 # 1 hour

  def perform(feed_onestop_id)
    begin
      feed = Feed.find_by_onestop_id!(feed_onestop_id)
      log "FeedFetcherWorker checking #{feed.onestop_id}"
      feed_version = FeedFetcherService.fetch_and_return_feed_version(feed)
      if feed_version
        log "FeedFetcherWorker checked #{feed.onestop_id} and found sha1: #{feed_version.sha1}"
      else
        log "FeedFetcherWorker checked #{feed.onestop_id} and didn't return a FeedVersion"
      end
    rescue Exception => e
      # NOTE: we're catching all exceptions, including Interrupt,
      #   SignalException, and SyntaxError
      logger.error e.message
      logger.error e.backtrace
      Raven.capture_exception(e) if defined?(Raven)
    end
  end
end
