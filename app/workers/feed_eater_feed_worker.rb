require 'gtfsgraph'

class FeedEaterFeedWorker < FeedEaterWorker
  sidekiq_options unique: true,
                  unique_job_expiration: 60 * 60, # 1 hour
                  log_duplicate_payload: true

  FEEDVALIDATOR_PATH = './virtualenv/bin/feedvalidator.py'

  def perform(feed_onestop_id, import_level=0)
    # Download the feed
    feed = Feed.find_by(onestop_id: feed_onestop_id)
    logger.info "FeedEaterFeedWorker #{feed_onestop_id}: Downloading #{feed.url}"
    updated = feed.fetch_and_check_for_updated_version
    return unless updated

    # Create import record
    feed_import = FeedImport.create(feed: feed)

    # Validate
    unless Figaro.env.feedvalidator_skip.present?
      logger.info "FeedEaterFeedWorker #{feed_onestop_id}: Validating feed"
      validation_report = IO.popen([
        FEEDVALIDATOR_PATH,
        '-n',
        '--output=CONSOLE',
        feed.file_path
      ]).read
      feed_import.update(validation_report: validation_report)
    end

    # Import feed
    begin
      logger.info "FeedEaterFeedWorker #{feed_onestop_id}: Importing feed at import level #{import_level}"
      graph = GTFSGraph.new(feed.file_path, feed)
      graph.load_gtfs
      operators = graph.load_tl
      graph.create_changeset operators, import_level
    rescue Exception => e
      # NOTE: we're catching all exceptions, including Interrupt,
      #   SignalException, and SyntaxError
      exception_log = "\n#{e}\n#{e.backtrace}\n"
      logger.error exception_log
      feed_import.update(success: false, exception_log: exception_log)
      Raven.capture_exception(e) if defined?(Raven)
    else
      logger.info "FeedEaterFeedWorker #{feed_onestop_id}: Saving successful import"
      feed.has_been_fetched_and_imported!(on_feed_import: feed_import)
    ensure
      # Save logs and reports
      logger.info "FeedEaterFeedWorker #{feed_onestop_id}: Saving log & report"
      feed_import.update(import_log: graph.import_log)
    end

    # Done
    logger.info "FeedEaterFeedWorker #{feed_onestop_id}: Done."
  end
end
