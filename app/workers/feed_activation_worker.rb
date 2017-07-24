class FeedActivationWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default,
                  retry: false

  def perform(feed_onestop_id, feed_version_sha1, import_level)
    FeedEaterService.activate_feed(
      feed_onestop_id,
      feed_version_sha1,
      import_level
    )
  end
end
