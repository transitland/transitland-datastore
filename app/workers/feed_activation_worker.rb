class FeedActivationWorker
  include Sidekiq::Worker

  def perform(feed_onestop_id, feed_version_sha1, import_level)
    logger.info "FeedActivationWorker #{feed_onestop_id}: activating #{feed_version_sha1} at import_level #{import_level}"
    # Find Feed & FeedVersions
    feed = Feed.find_by_onestop_id!(feed_onestop_id)
    new_active_feed_version = feed.feed_versions.find_by!(sha1: feed_version_sha1)
    old_active_feed_version = feed.active_feed_version
    # Activate new FeedVersion
    feed.activate_feed_version(new_active_feed_version.sha1, import_level)
    # Deactivate old FeedVersion
    if old_active_feed_version && old_active_feed_version != new_active_feed_version
      FeedDeactivationWorker.perform_async(feed_onestop_id, old_active_feed_version.sha1)
    end
  end
end
