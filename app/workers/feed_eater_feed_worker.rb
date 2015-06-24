class FeedEaterFeedWorker
  include Sidekiq::Worker

  PYTHON = './virtualenv/bin/python'
  FEEDVALIDATOR = './virtualenv/bin/feedvalidator.py'

  def perform(feed_onestop_id)
    # Download the feed
    puts "feed_onestop_id: #{feed_onestop_id}"
    feed = Feed.find_by(onestop_id: feed_onestop_id)
    logger.info "FeedEaterFeedWorker #{feed_onestop_id}: Downloading #{feed.url}"
    updated = feed.fetch_and_check_for_updated_version
    return unless updated

    # Clear out old log files
    log_file_path = FeedEaterFeedWorker.artifact_file_path("#{feed_onestop_id}.log")
    validation_report_path = FeedEaterFeedWorker.artifact_file_path("#{feed_onestop_id}.html")
    FileUtils.rm(log_file_path) if File.exist?(log_file_path)
    FileUtils.rm(validation_report_path) if File.exist?(validation_report_path)

    # Create import record
    feed_import = FeedImport.create(feed: feed)

    # Validate and import feed
    begin
      logger.info "FeedEaterFeedWorker #{feed_onestop_id}: Validating feed"
      run_python('./lib/feedeater/validate.py', "--feedvalidator #{FEEDVALIDATOR} --log #{log_file_path} #{feed_onestop_id}")
      logger.info "FeedEaterFeedWorker #{feed_onestop_id}: Uploading feed"
      run_python('./lib/feedeater/post.py', "--log #{log_file_path} #{feed_onestop_id}")
      logger.info "FeedEaterFeedWorker #{feed_onestop_id}: Creating GTFS artifact"
      run_python('./lib/feedeater/artifact.py', "--log #{log_file_path} #{feed_onestop_id}")
      if Figaro.env.upload_feed_eater_artifacts_to_s3.present? &&
         Figaro.env.upload_feed_eater_artifacts_to_s3 == 'true'
        logger.info "FeedEaterFeedWorker #{feed_onestop_id}: Enqueuing a job to upload artifacts to S3"
        UploadFeedEaterArtifactsToS3Worker.perform_async(feed_onestop_id)
      end
    rescue Exception => e
      # NOTE: we're catching all exceptions, including Interrupt,
      #   SignalException, and SyntaxError
      exception_log = "\n#{e}\n#{e.backtrace}\n"
      logger.error exception_log
      feed_import.update(success: false)
      Raven.capture_exception(e) if defined?(Raven)
    else
      logger.info "FeedEaterFeedWorker #{feed_onestop_id}: Saving successful import"
      feed.has_been_fetched_and_imported!(on_feed_import: feed_import)
    ensure
      # Cleanup
      import_log = ''
      if File.exist?(log_file_path)
        import_log = File.open(log_file_path, 'r').read
      end
      if exception_log.present?
        import_log << exception_log
      end
      validation_report = nil
      if File.exist?(validation_report_path)
        validation_report = File.open(validation_report_path, 'r').read
      end
      # Save logs and reports
      logger.info "FeedEaterFeedWorker #{feed_onestop_id}: Saving log & report"
      feed_import.update(
        import_log: import_log,
        validation_report: validation_report
      )
    end
  end

  private

  def run_python(file, args)
    success = system("#{PYTHON} #{file} #{args}")
    raise "Error running Python #{file} #{args}" if !success
  end

  def self.artifact_file_path(name)
    File.join(Figaro.env.transitland_feed_data_path, name)
  end
end
