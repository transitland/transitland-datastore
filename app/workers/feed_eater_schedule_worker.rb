require 'gtfsgraph'

class FeedEaterScheduleWorker < FeedEaterWorker
  def perform(feed_onestop_id, feed_import_id, trip_ids, agency_map, route_map, stop_map)
    logger.info "FeedEaterScheduleWorker #{feed_onestop_id}: Importing #{trip_ids.size} trips"
    feed = Feed.find_by(onestop_id: feed_onestop_id)
    feed_import = FeedImport.find(feed_import_id)
    feed_schedule_import = FeedScheduleImport.create(feed_import: feed_import)
    graph = nil
    begin
      graph = GTFSGraph.new(feed.file_path, feed)
      graph.ssp_perform_async(
        trip_ids,
        agency_map,
        route_map,
        stop_map
      )
    rescue Exception => e
      exception_log = "\n#{e}\n#{e.backtrace}\n"
      logger.error exception_log
      feed_schedule_import.update(success: false, exception_log: exception_log)
      # Raven.capture_exception(e) if defined?(Raven)
    else
      logger.info "FeedEaterScheduleWorker #{feed_onestop_id}: Saving successful import"
      feed_schedule_import.update(success: true)
    ensure
      logger.info "FeedEaterScheduleWorker #{feed_onestop_id}: Saving log & report"
      feed_schedule_import.update(import_log: graph.try(:import_log))
    end
  end
end
