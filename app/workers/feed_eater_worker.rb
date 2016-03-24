class FeedEaterWorker
  include Sidekiq::Worker

  sidekiq_options unique: :until_and_while_executing,
                  unique_job_expiration: 60 * 60, # 1 hour
                  log_duplicate_payload: true,
                  queue: :feed_eater

  FEEDVALIDATOR_PATH = './virtualenv/bin/feedvalidator.py'

  def perform(feed_onestop_id, feed_version_sha1=nil, import_level=0)
    feed = Feed.find_by!(onestop_id: feed_onestop_id)

    if feed_version_sha1.present?
      feed_version = feed.feed_versions.find_by!(sha1: feed_version_sha1)
    else
      feed_version = feed.feed_versions.first!
    end

    # make sure to have local copy of file
    feed_file_path = feed_version.file.local_path_copying_locally_if_needed

    # Create import record
    feed_version_import = feed_version.feed_version_imports.create(
      import_level: import_level
    )

    # Validate
    unless Figaro.env.run_google_feedvalidator.present? &&
           Figaro.env.run_google_feedvalidator == 'false'
      logger.info "FeedEaterWorker #{feed_onestop_id}: Validating feed"
      validation_report = IO.popen([
        FEEDVALIDATOR_PATH,
        '-n',
        '--output=CONSOLE',
        feed_file_path
      ]).read
      feed_version_import.update(validation_report: validation_report)
    end

    # Import feed
    graph = nil
    begin
      logger.info "FeedEaterWorker #{feed_onestop_id}: Importing feed at import level #{import_level}"
      graph = GTFSGraph.new(feed_file_path, feed, feed_version)
      graph.cleanup
      graph.create_change_osr
      if import_level >= 2
        schedule_jobs = []
        graph.ssp_schedule_async do |trip_ids, agency_map, route_map, stop_map, rsp_map|
          # Create FeedScheduleImport record for FESW job
          feed_schedule_import = feed_version_import.feed_schedule_imports.create!
          # Don't enqueue immediately to avoid races
          schedule_jobs << [feed_schedule_import.id, trip_ids, agency_map, route_map, stop_map, rsp_map]
        end
        schedule_jobs.each do |feed_schedule_import_id, trip_ids, agency_map, route_map, stop_map, rsp_map|
          logger.info "FeedEaterWorker #{feed_onestop_id}: Enqueue schedule job"
          FeedEaterScheduleWorker.perform_async(feed.onestop_id, feed_version.sha1, feed_schedule_import_id, trip_ids, agency_map, route_map, stop_map, rsp_map)
        end
      end
    rescue Exception => e
      # NOTE: we're catching all exceptions, including Interrupt,
      #   SignalException, and SyntaxError
      exception_log = "\n#{e}\n#{e.backtrace}\n"
      logger.error exception_log
      logger.info "FeedEaterWorker #{feed_onestop_id}: Saving failed feed import"
      feed_version_import.failed(exception_log: exception_log)
      Raven.capture_exception(e) if defined?(Raven)
    else
      # Enqueue FeedEaterScheduleWorker jobs, or save successful import.
      if import_level < 2
        logger.info "FeedEaterWorker #{feed_onestop_id}: Saving successful feed import"
        feed_version_import.succeeded
      end
    ensure
      feed_version.file.remove_any_local_cached_copies
      # Save logs and reports
      logger.info "FeedEaterWorker #{feed_onestop_id}: Saving log"
      feed_version_import.update(import_log: graph.try(:import_log))
    end
  end
end


if __FILE__ == $0
  require 'sidekiq/testing'
  Sidekiq::Testing.inline!
  ActiveRecord::Base.logger = Logger.new(STDOUT)
  feed_onestop_id = ARGV[0] || 'f-9q9-caltrain'
  path = ARGV[1] || File.open(Rails.root.join('spec/support/example_gtfs_archives/f-9q9-caltrain.zip'))
  import_level = (ARGV[2].presence || 1).to_i
  feed = Feed.find_by_onestop_id!(feed_onestop_id)
  feed_version = feed.feed_versions.create!(file: File.open(path))
  FeedEaterWorker.perform_async(feed.onestop_id, feed_version.sha1, import_level)
end
