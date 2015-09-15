class GtfsFeedArtifactWorker < FeedEaterWorker

  MAX_ATTEMPTS = 10
  WAIT_TIME = 10.minutes

  def perform(feed_onestop_id, attempts=1)
    feed = Feed.find_by(onestop_id: feed_onestop_id)
    missing = feed.stops.select { |stop| stop.tags['osm_way_id'].nil? }
    if attempts > MAX_ATTEMPTS
      logger.info "GtfsFeedArtifactWorker #{feed_onestop_id}: Missing #{missing.length} osm_way_ids. #{attempts} attempts, aborting"
      return
    elsif missing.any?
      logger.info "GtfsFeedArtifactWorker #{feed_onestop_id}: Missing #{missing.length} osm_way_ids. #{attempts} attempts, trying again"
      GtfsFeedArtifactWorker.perform_in(WAIT_TIME, feed_onestop_id, attempts+1)
      return
    end

    artifact_path = create_artifact(feed)

    if Figaro.env.upload_feed_eater_artifacts_to_s3 == 'true'
      logger.info "GtfsFeedArtifactWorker #{feed_onestop_id}: Enqueuing a job to upload artifacts to S3"
      UploadFeedEaterArtifactsToS3Worker.perform_async(feed_onestop_id)
    end

    logger.info "GtfsFeedArtifactWorker #{feed_onestop_id}: Done."
  end  
  
  def create_artifact(feed)  
    # Open GTFS feed; this unzips to a temp dir.
    gtfs_feed = GTFS::Source.build(feed.file_path, {strict: false})
    # Access the tmp_dir. 
    # TODO: Monkey patch gtfs_feed attr_accessor?
    tmp_dir = gtfs_feed.instance_variable_get(:@tmp_dir)
    # Read the CSV file directly:
    #   gtfs_feed.stops changes column names, ignores extras.
    # Write back out as-is, but with onestop_id and osm_way_id columns.
    reader = CSV.open(File.join(tmp_dir, 'stops.txt'))
    header = reader.shift
    header << 'onestop_id'
    header << 'osm_way_id'
    column = header.index('stop_id')
    writer = CSV.open(File.join(tmp_dir, 'stops.onestop_id.txt'), 'wb')
    writer << header
    reader.each do |row|
      # Find a Stop for this gtfs stop.
      stop_id = row[column]
      identifier = OnestopId::create_identifier(feed.onestop_id, 's', stop_id)
      found = Stop.with_identifier(identifier).first      
      row << found.onestop_id
      row << found.tags['osm_way_id']
      writer << row
    end
    reader.close
    writer.close
    # Overwrite the original stops.txt
    File.rename(writer.path, reader.path)
    # Create the artifact zip
    artifact_path = File.join(
      Figaro.env.transitland_feed_data_path, 
      "#{feed.onestop_id}.artifact.zip"
    )
    # Remove if exists
    File.unlink(artifact_path) if File.exists?(artifact_path)
    # Create new artifact zip; include all files.
    Zip::File.open(artifact_path, Zip::File::CREATE) do |zipfile|
      Dir.entries(tmp_dir)
        .select { |f| File.file? File.join(tmp_dir, f) }
        .each { |f| zipfile.add(f, File.join(tmp_dir, f)) }
    end
    gtfs_feed = nil
    artifact_path
  end
end
