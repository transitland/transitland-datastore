class FeedEaterScheduleWorker
  include Sidekiq::Worker
  sidekiq_options queue: :feed_eater_schedule,
                  retry: false

  def perform(feed_onestop_id, feed_version_sha1, feed_schedule_import_id, trip_ids, agency_map, route_map, stop_map, rsp_map)
    FeedEaterService.import_level_2(
      feed_onestop_id,
      feed_version_sha1,
      feed_schedule_import_id,
      trip_ids,
      agency_map,
      route_map,
      stop_map,
      rsp_map
    )
  end
end
