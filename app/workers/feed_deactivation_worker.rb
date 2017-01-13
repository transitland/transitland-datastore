class FeedDeactivationWorker
  include Sidekiq::Worker

  def perform(feed_onestop_id, feed_version_sha1)
    log "FeedDeactivationWorker #{feed_onestop_id}: deactivating #{feed_version_sha1}"
    # Find Feed & FeedVersions
    feed = Feed.find_by_onestop_id!(feed_onestop_id)
    old_active_feed_version = feed.feed_versions.find_by!(sha1: feed_version_sha1)
    # Deactivate old FeedVersion
    feed.deactivate_feed_version(feed_version_sha1)
  end
end
