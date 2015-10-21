require 'gtfsgraph'

class FeedEaterFeedWorker < FeedEaterWorker
  sidekiq_options unique: true,
                  unique_job_expiration: 60 * 60, # 1 hour
                  log_duplicate_payload: true,
                  queue: :feed_eater_feed

  FEEDVALIDATOR_PATH = './virtualenv/bin/feedvalidator.py'

  def perform(feed_onestop_id, import_level=0)
    # Download the feed
    feed = Feed.find_by(onestop_id: feed_onestop_id)
    logger.info "FeedEaterFeedWorker #{feed_onestop_id}: Downloading #{feed.url}"
    feed_version = feed.fetch_and_return_feed_version
    return unless feed_version.present?

    # make sure to have local copy of file
    feed_file_path = feed_version.file.local_path_copying_locally_if_needed

    # Create import record
    feed_version_import = feed_version.feed_version_imports.create

    # Validate
    unless Figaro.env.run_google_feedvalidator.present? &&
           Figaro.env.run_google_feedvalidator == 'false'
      logger.info "FeedEaterFeedWorker #{feed_onestop_id}: Validating feed"
      validation_report = IO.popen([
        FEEDVALIDATOR_PATH,
        '-n',
        '--output=CONSOLE',
        feed_file_path
      ]).read
      feed_version_import.update(validation_report: validation_report)
    end

    # Import feed
    logger.info "FeedEaterFeedWorker #{feed_onestop_id}: Importing feed at import level #{import_level}"
    graph = nil
    begin
      graph = GTFSGraph.new(feed_file_path, feed)
      graph.create_change_osr(import_level)
      if import_level >= 2
        schedule_jobs = []
        graph.ssp_schedule_async do |trip_ids, agency_map, route_map, stop_map|
          # Create FeedScheduleImport record for FESW job
          feed_schedule_import = feed_version_import.feed_schedule_imports.create!
          # Don't enqueue immediately to avoid races
          schedule_jobs << [feed_schedule_import.id, trip_ids, agency_map, route_map, stop_map]
        end
        schedule_jobs.each do |feed_schedule_import_id, trip_ids, agency_map, route_map, stop_map|
          logger.info "FeedEaterFeedWorker #{feed_onestop_id}: Enqueue schedule job"
          FeedEaterScheduleWorker.perform_async(feed.onestop_id, feed_version.sha1, feed_schedule_import_id, trip_ids, agency_map, route_map, stop_map)
        end
      end
    rescue Exception => e
      # NOTE: we're catching all exceptions, including Interrupt,
      #   SignalException, and SyntaxError
      exception_log = "\n#{e}\n#{e.backtrace}\n"
      logger.error exception_log
      logger.info "FeedEaterFeedWorker #{feed_onestop_id}: Saving failed feed import"
      feed_version_import.failed(exception_log: exception_log)
      Raven.capture_exception(e) if defined?(Raven)
    else
      # Enqueue FeedEaterScheduleWorker jobs, or save successful import.
      if import_level < 2
        logger.info "FeedEaterFeedWorker #{feed_onestop_id}: Saving successful feed import"
        feed_version_import.succeeded
      end
      # Enqueue GTFS Artifact Workers (~ Vestigial)
      if Figaro.env.create_feed_eater_artifacts == 'true' &&
         Figaro.env.auto_conflate_stops_with_osm == 'true'
        logger.info "FeedEaterFeedWorker #{feed_onestop_id}: Enqueue artifact job"
        GtfsFeedArtifactWorker.perform_async(feed_onestop_id)
      end
    ensure
      feed_version.file.remove_any_local_cached_copies
      # Save logs and reports
      logger.info "FeedEaterFeedWorker #{feed_onestop_id}: Saving log"
      feed_version_import.update(import_log: graph.try(:import_log))
    end
  end
end
