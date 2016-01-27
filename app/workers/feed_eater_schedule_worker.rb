class FeedEaterScheduleWorker
  include Sidekiq::Worker

  sidekiq_options queue: :feed_eater_schedule

  def perform(feed_onestop_id, feed_version_sha1, feed_schedule_import_id, trip_ids, agency_map, route_map, stop_map, rsp_map)
    logger.info "FeedEaterScheduleWorker #{feed_onestop_id}: Importing #{trip_ids.size} trips"
    feed = Feed.find_by(onestop_id: feed_onestop_id)
    feed_version = FeedVersion.find_by(sha1: feed_version_sha1)
    feed_file_path = feed_version.file.local_path_copying_locally_if_needed
    feed_schedule_import = FeedScheduleImport.find(feed_schedule_import_id)
    graph = nil
    begin
      graph = GTFSGraph.new(feed_file_path, feed, feed_version)
      graph.ssp_perform_async(
        trip_ids,
        agency_map,
        route_map,
        stop_map,
        rsp_map
      )
    rescue Exception => e
      exception_log = "\n#{e}\n#{e.backtrace}\n"
      logger.error exception_log
      feed_schedule_import.failed(exception_log: exception_log)
      Raven.capture_exception(e) if defined?(Raven)
    else
      logger.info "FeedEaterScheduleWorker #{feed_onestop_id}: Saving successful schedule import"
      feed_schedule_import.succeeded
    ensure
      feed_version.file.remove_any_local_cached_copies
      logger.info "FeedEaterScheduleWorker #{feed_onestop_id}: Saving log"
      feed_schedule_import.update(import_log: graph.try(:import_log))
    end
  end
end
