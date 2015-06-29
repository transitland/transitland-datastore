class GtfsFeedArtifactWorker < FeedEaterWorker

  MAX_ATTEMPTS = 5
  WAIT_TIME = 10.minutes

  def perform(feed_onestop_id, attempts=1)
    logger.info "GtfsFeedArtifactWorker #{feed_onestop_id}: Verifying osm_way_ids"
    prefix = "gtfs://#{feed_onestop_id}/"
    missing = Stop.with_identifer_starting_with(prefix).select { |x| x.tags['osm_way_id'].nil? }

    if attempts > MAX_ATTEMPTS
      logger.info "GtfsFeedArtifactWorker #{feed_onestop_id}: Missing #{missing.length} osm_way_ids. #{attempts} attempts, aborting"
      return
    elsif missing.any?
      logger.info "GtfsFeedArtifactWorker #{feed_onestop_id}: Missing #{missing.length} osm_way_ids. #{attempts} attempts, trying again"
      GtfsFeedArtifactWorker.perform_in(WAIT_TIME, feed_onestop_id, attempts+1)
      return
    end

    logger.info "GtfsFeedArtifactWorker #{feed_onestop_id}: Creating GTFS artifacts"
    run_python(
      './lib/feedeater/artifact.py',
      '--quiet',
      feed_onestop_id
    )

    if Figaro.env.upload_feed_eater_artifacts_to_s3 == 'true'
      logger.info "GtfsFeedArtifactWorker #{feed_onestop_id}: Enqueuing a job to upload artifacts to S3"
      UploadFeedEaterArtifactsToS3Worker.perform_async(feed_onestop_id)
    end

    logger.info "GtfsFeedArtifactWorker #{feed_onestop_id}: Done."

  end
end
