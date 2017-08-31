class GTFSGoogleValidationWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low,
                  retry: false,
                  unique: :until_and_while_executing,
                  unique_job_expiration: 22 * 60 * 60, # 22 hours
                  log_duplicate_payload: true

  def perform(feed_version_sha1)
    feed_version = FeedVersion.find_by!(sha1: feed_version_sha1)
    GTFSValidationService.create_google_validation(feed_version)
  end
end
