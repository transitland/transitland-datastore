class FeedEaterFeedWorker < FeedEaterWorker
  def perform(feed_onestop_id)
    # Download the feed
    feed = Feed.find_by(onestop_id: feed_onestop_id)
    logger.info "FeedEaterFeedWorker #{feed_onestop_id}: Downloading #{feed.url}"
    updated = feed.fetch_and_check_for_updated_version
    # return unless updated

    # Clear out old log files
    log_file_path = artifact_file_path("#{feed_onestop_id}.log")
    validation_report_path = artifact_file_path("#{feed_onestop_id}.html")
    FileUtils.rm(log_file_path) if File.exist?(log_file_path)
    FileUtils.rm(validation_report_path) if File.exist?(validation_report_path)

    # Create import record
    feed_import = FeedImport.create(feed: feed)

    # Validate and import feed
    begin
      logger.info "FeedEaterFeedWorker #{feed_onestop_id}: Validating feed"
      feedvalidator = Figaro.env.feedvalidator_path || './virtualenv/bin/python'
      run_python(
        './lib/feedeater/validate.py',
        '--feedvalidator',
        feedvalidator,
        '--log',
        log_file_path,
        feed_onestop_id
      )
      logger.info "FeedEaterFeedWorker #{feed_onestop_id}: Uploading feed"
      # run_python(
      #   './lib/feedeater/post.py',
      #   '--log',
      #   log_file_path,
      #   feed_onestop_id
      # )
      logger.info "FeedEaterFeedWorker #{feed_onestop_id}: Enqueue artifact job"
      GtfsFeedArtifactWorker.perform_async(feed_onestop_id)
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
end
