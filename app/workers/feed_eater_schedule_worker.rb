class FeedEaterScheduleWorker
  include Sidekiq::Worker

  sidekiq_options queue: :feed_eater_schedule, retry: false

  def perform(feed_onestop_id, feed_version_sha1, feed_schedule_import_id, trip_ids, agency_map, route_map, stop_map, rsp_map)
    log "FeedEaterScheduleWorker #{feed_onestop_id}: Importing #{trip_ids.size} trips"
    feed = Feed.find_by(onestop_id: feed_onestop_id)
    feed_version = FeedVersion.find_by(sha1: feed_version_sha1)
    feed_schedule_import = FeedScheduleImport.find(feed_schedule_import_id)
    import_level = feed_schedule_import.feed_version_import.import_level
    graph = nil
    begin
      graph = GTFSGraph.new(feed, feed_version)
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
end
