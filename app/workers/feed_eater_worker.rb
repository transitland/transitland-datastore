class FeedEaterWorker
  include Sidekiq::Worker

  def perform(feed_onestop_ids: [])
    # TODO: datastore_api_base_url = Figaro.env.DATASTORE_PROTOCOL + "://" + Figaro.env.DATASTORE_HOST +
    logger.info '0. Fetching latest onestop-id-registry'
    OnestopIdClient::Registry.repo(force_update: true)

    logger.info '1. Checking for new feeds'
    python = './virtualenv/bin/python'
    updated = `#{python} ./lib/feedeater/check.py #{feed_onestop_ids.join(' ')}`
    updated = updated.split()
    logger.info " -> #{updated.join(' ')}"

    logger.info '2. Downloading feeds that have been updated'
    system "#{python} ./lib/feedeater/fetch.py #{updated.join(' ')}"

    logger.info '3. Validating feeds'
    system "#{python} ./lib/feedeater/validate.py #{updated.join(' ')}"
    
    logger.info '4. Uploading feed to datastore'
    system "#{python} ./lib/feedeater/post.py #{updated.join(' ')}"

    logger.info '5. Creating GTFS artifacts'
    system "#{python} ./lib/feedeater/artifact.py #{updated.join(' ')}"
  
    # logger.info '5. Creating FeedEater Reports'

    # logger.info '6. Uploading to S3'
    # aws s3 sync . s3://onestop-feed-cache.transit.land
  end
end
