class FeedEaterService
  include Singleton

  VERSION = 2

  def self.import_level_1(feed_onestop_id, feed_version_sha1: nil, import_level: 0, version: nil, block_before_level_1: nil, block_before_level_2: nil)
    # Get the correct Importer version
    version ||= VERSION
    importer = (version == 1 ? GTFSGraph : GTFSGraphImporter)
    # These are only for testing
    block_before_level_1 ||= Proc.new { |graph| }
    block_before_level_2 ||= Proc.new { |graph| }

    # Fallback to newest FeedVersion
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
      graph = importer.new(feed, feed_version)
      block_before_level_1.call(graph) # for testing/debug
      graph.create_change_osr
      block_before_level_2.call(graph) # for testing/debug
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
        FeedActivationWorker.perform_async(
          feed.onestop_id,
          feed_version.sha1,
          import_level
        )
      end
    ensure
      feed_version.file.remove_any_local_cached_copies
      # Save logs and reports
      log "FeedEaterWorker #{feed_onestop_id}: Saving log"
      feed_version_import.update(import_log: graph.try(:import_log))
    end
  end

  def self.import_level_2(feed_onestop_id, feed_version_sha1, feed_schedule_import_id, trip_ids, agency_map, route_map, stop_map, rsp_map, version: nil)
    version ||= VERSION
    importer = (version == 1 ? GTFSGraph : GTFSScheduleImporter)

    log "FeedEaterScheduleWorker #{feed_onestop_id}: Importing #{trip_ids.size} trips"
    feed = Feed.find_by(onestop_id: feed_onestop_id)
    feed_version = FeedVersion.find_by(sha1: feed_version_sha1)
    feed_schedule_import = FeedScheduleImport.find(feed_schedule_import_id)
    import_level = feed_schedule_import.feed_version_import.import_level
    graph = nil
    begin
      graph = importer.new(feed, feed_version)
      graph.ssp_perform_async(
        trip_ids,
        agency_map,
        route_map,
        stop_map,
        rsp_map
      )
    rescue Exception => e
      exception_log = "\n#{e}\n#{e.backtrace}\n"
      log exception_log, :error
      feed_schedule_import.failed(exception_log: exception_log)
      if defined?(Raven)
        Raven.capture_exception(e, {
          tags: {
            'feed_onestop_id' => feed_onestop_id,
            'feed_version_sha1' => feed_version_sha1
          }
        })
      end
    else
      log "FeedEaterScheduleWorker #{feed_onestop_id}: Saving successful schedule import"
      feed_schedule_import.succeeded
      if feed_schedule_import.all_succeeded?
        log "FeedEaterScheduleWorker #{feed_onestop_id}: Enqueing FeedActivationWorker: #{feed.onestop_id} #{feed_version.sha1}, import_level #{import_level}"
        FeedActivationWorker.perform_async(
          feed.onestop_id,
          feed_version.sha1,
          import_level
        )
      end
    ensure
      feed_version.file.remove_any_local_cached_copies
      log "FeedEaterScheduleWorker #{feed_onestop_id}: Saving log"
      feed_schedule_import.update(import_log: graph.try(:import_log))
    end
  end

  def self.check_activate_feed(feed_schedule_import_id)
    feed_schedule_import = FeedScheduleImport.find(feed_schedule_import_id)
    if feed_schedule_import.all_succeeded?
      log "FeedEaterScheduleWorker #{feed_onestop_id}: Enqueing FeedActivationWorker: #{feed.onestop_id} #{feed_version.sha1}, import_level #{import_level}"
      FeedActivationWorker.perform_async(
        feed.onestop_id,
        feed_version.sha1,
        import_level
      )
    end
  end

  def self.activate_feed(feed_onestop_id, feed_version_sha1, import_level)
    log "FeedActivationWorker #{feed_onestop_id}: activating #{feed_version_sha1} at import_level #{import_level}"
    # Find Feed & FeedVersions
    feed = Feed.find_by_onestop_id!(feed_onestop_id)
    new_active_feed_version = feed.feed_versions.find_by!(sha1: feed_version_sha1)
    old_active_feed_version = feed.active_feed_version
    # Activate new FeedVersion
    feed.activate_feed_version(new_active_feed_version.sha1, import_level)
    # Deactivate old FeedVersion
    if old_active_feed_version && old_active_feed_version != new_active_feed_version
      FeedDeactivationWorker.perform_async(feed_onestop_id, old_active_feed_version.sha1)
    end
  end

  def self.deactivate_feed(feed_onestop_id, feed_version_sha1)
    log "FeedDeactivationWorker #{feed_onestop_id}: deactivating #{feed_version_sha1}"
    # Find Feed & FeedVersions
    feed = Feed.find_by_onestop_id!(feed_onestop_id)
    old_active_feed_version = feed.feed_versions.find_by!(sha1: feed_version_sha1)
    # Deactivate old FeedVersion
    feed.deactivate_feed_version(feed_version_sha1)
  end
end
