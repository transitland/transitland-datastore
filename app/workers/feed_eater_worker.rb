class FeedEaterWorker
  include Sidekiq::Worker

  def perform(feed_onestop_ids: [])
    # TODO: datastore_api_base_url = Figaro.env.DATASTORE_PROTOCOL + "://" + Figaro.env.DATASTORE_HOST +
    logger.info '0. Fetching latest transitland-feed-registry'
    TransitlandClient::FeedRegistry.repo(force_update: true)

    logger.info '1. Checking for new feeds'
    updated = `python -m feedeater.check #{feed_onestop_ids.join(' ')}`
    updated = updated.split()
    logger.info " -> #{updated.join(' ')}"

    logger.info '2. Downloading feeds that have been updated'
    system "python -m feedeater.fetch #{updated.join(' ')}"

    logger.info '3. Validating feeds'
    system "python -m feedeater.validate #{updated.join(' ')}"
    
    logger.info '4. Uploading feed to datastore'
    system "python -m feedeater.post #{updated.join(' ')}"

    logger.info '5. Creating GTFS artifacts'
    system "python -m feedeater.artifact #{updated.join(' ')}"
  
    # logger.info '5. Creating FeedEater Reports'

    # logger.info '6. Uploading to S3'
    # aws s3 sync . s3://onestop-feed-cache.transit.land
  end
end
