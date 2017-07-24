class FeedEaterWorker
  include Sidekiq::Worker
  sidekiq_options queue: :feed_eater,
                  retry: false,
                  unique: :until_and_while_executing,
                  unique_job_expiration: 60 * 60 * 22, # 22 hours
                  log_duplicate_payload: true

  def perform(feed_onestop_id, feed_version_sha1=nil, import_level=0)
    FeedEaterService.import_level_1(
      feed_onestop_id,
      feed_version_sha1: feed_version_sha1,
      import_level: import_level
    )
  end
end
