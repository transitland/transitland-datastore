class FeedValidationWorker
  include Sidekiq::Worker

  sidekiq_options unique: :until_and_while_executing,
                  unique_job_expiration: 22 * 60 * 60 # 22 hours

  def perform(feed_version_sha1)
    # do stuff
  end
end
