class FeedActivationWorker
  include Sidekiq::Worker

  def perform(feed_onestop_id, feed_version_sha1, import_level)
    logger.info "FeedActivationWorker #{feed_onestop_id}: activating #{feed_version_sha1} at import_level #{import_level}"
    Feed.find_by_onestop_id!(feed_onestop_id).activate_feed_version(feed_version_sha1, import_level)
  end
end
