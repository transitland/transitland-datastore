class FeedEaterWorker
  include Sidekiq::Worker

  def perform(feed_onestop_ids = [], import_level = 0)
    logger.info 'FeedEaterWorker: Update feeds from feed registry'
    Feed.update_feeds_from_feed_registry
    feeds = feed_onestop_ids.length > 0 ? Feed.where(onestop_id: feed_onestop_ids) : Feed.where('')
    feeds.each do |feed|
      logger.info "FeedEaterWorker: Enqueue #{feed.onestop_id} at import level #{import_level}"
      FeedEaterFeedWorker.perform_async(feed.onestop_id, import_level)
    end
    logger.info 'FeedEaterWorker: Done.'
  end

  private

end
