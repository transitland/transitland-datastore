require 'gtfsgraph'

class FeedEaterScheduleWorker < FeedEaterWorker
  def perform(feed_onestop_id, trip_ids, agency_map, route_map, stop_map)
    feed = Feed.find_by(onestop_id: feed_onestop_id)
    graph = GTFSGraph.new(feed.file_path, feed)
    graph.load_gtfs
    graph.ssp_perform_async(
      trip_ids,
      agency_map,
      route_map,
      stop_map
    )
  end
end
