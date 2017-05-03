class FeedEaterWorker
  include Sidekiq::Worker
  sidekiq_options queue: :feed_eater,
                  retry: false,
                  unique: :until_and_while_executing,
                  unique_job_expiration: 60 * 60 * 22, # 22 hours
                  log_duplicate_payload: true

  def perform(feed_onestop_id, feed_version_sha1=nil, import_level=0)
    feed = Feed.find_by!(onestop_id: feed_onestop_id)

    if feed_version_sha1.present?
      feed_version = feed.feed_versions.find_by!(sha1: feed_version_sha1)
    else
      feed_version = feed.feed_versions.first!
    end

  # Create import record
    feed_version_import = feed_version.feed_version_imports.create(
      import_level: import_level
    )

    # Import feed
    graph = nil
    begin
      log "FeedEaterWorker #{feed_onestop_id}: Importing feed at import level #{import_level}"
      graph = GTFSGraph.new(feed, feed_version)
      graph.create_change_osr
      graph.cleanup
      if import_level >= 2
        schedule_jobs = []
        graph.ssp_schedule_async do |trip_ids, agency_map, route_map, stop_map, rsp_map|
          # Create FeedScheduleImport record for FESW job
          feed_schedule_import = feed_version_import.feed_schedule_imports.create!
          # Don't enqueue immediately to avoid races
          schedule_jobs << [feed_schedule_import.id, trip_ids, agency_map, route_map, stop_map, rsp_map]
        end
        schedule_jobs.each do |feed_schedule_import_id, trip_ids, agency_map, route_map, stop_map, rsp_map|
          log "FeedEaterWorker #{feed_onestop_id}: Enqueue schedule job"
          FeedEaterScheduleWorker.perform_async(feed.onestop_id, feed_version.sha1, feed_schedule_import_id, trip_ids, agency_map, route_map, stop_map, rsp_map)
        end
      end
    rescue Exception => e
      # NOTE: we're catching all exceptions, including Interrupt,
      #   SignalException, and SyntaxError
      exception_log = "\n#{e}\n#{e.backtrace}\n"
      log exception_log, :error
      log "FeedEaterWorker #{feed_onestop_id}: Saving failed feed import"
      feed_version_import.failed(exception_log: exception_log)
      if defined?(Raven)
        Raven.capture_exception(e, {
          tags: {
            'feed_onestop_id' => feed_onestop_id,
            'feed_version_sha1' => feed_version.try(:sha1)
          }
        })
      end
    else
      # Enqueue FeedEaterScheduleWorker jobs, or save successful import.
      if import_level < 2
        log "FeedEaterWorker #{feed_onestop_id}: Saving successful feed import"
        feed_version_import.succeeded
      end
    ensure
      feed_version.file.remove_any_local_cached_copies
      # Save logs and reports
      log "FeedEaterWorker #{feed_onestop_id}: Saving log"
      feed_version_import.update(import_log: graph.try(:import_log))
    end
  end
end
