class FeedEaterWorker
  include Sidekiq::Worker

  def perform(feed_onestop_ids = [])
    logger.info 'FeedEaterWorker: Update feeds from feed registry'
    Feed.update_feeds_from_feed_registry
    feeds = feed_onestop_ids.length > 0 ? Feed.where(onestop_id: feed_onestop_ids) : Feed.where('')
    feeds.each do |feed|
      FeedEaterFeedWorker.perform_async(feed.onestop_id)
    end
  end
end
