class GTFSImportWorker
  include Sidekiq::Worker
  sidekiq_options queue: :feed_eater,
                  retry: false,
                  unique: :until_and_while_executing,
                  unique_job_expiration: 22 * 60 * 60, # 22 hours
                  log_duplicate_payload: true
  
  def perform(feed_version_sha1, import_level=2)
    feed_version = FeedVersion.find_by!(sha1: feed_version_sha1)
    g = GTFSImportService.new(feed_version)
    g.clean_start
    g.import_with_log(import_level: import_level)
  end
end
