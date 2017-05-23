class FeedDeactivationWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default,
                  retry: false

  def perform(feed_onestop_id, feed_version_sha1)
    FeedEaterService.deactivate_feed(
      feed_onestop_id,
      feed_version_sha1
    )
  end
end
