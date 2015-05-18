class FeedEaterWorker
  include Sidekiq::Worker

  def perform(feed_onestop_ids: [])
    # TODO: datastore_api_base_url = Figaro.env.DATASTORE_PROTOCOL + "://" + Figaro.env.DATASTORE_HOST +
    logger.info '0. Fetching latest onestop-id-registry'
    OnestopIdClient::Registry.repo(force_update: true)

    logger.info '1. Downloading feeds that have been updated'
    system "python -m feedeater.fetch #{feed_onestop_ids.join(' ')}"

    logger.info '1. Validating feeds'
    system "python -m feedeater.validate #{feed_onestop_ids.join(' ')}"
    
    logger.info '3. Uploading feed to datastore'
    system "pythom -m feedeater.post #{feed_onestop_ids.join(' ')}"

    logger.info '4. Creating GTFS artifacts'
    system "python -m feedeater.artifact #{feed_onestop_ids.join(' ')}"
  
    # logger.info '5. Creating FeedEater Reports'

    # logger.info '6. Uploading to S3'
  end
end
