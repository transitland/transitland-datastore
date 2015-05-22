class FeedEaterWorker
  include Sidekiq::Worker

  def perform(feed_onestop_ids = [])
    # TODO: datastore_api_base_url = Figaro.env.DATASTORE_PROTOCOL + "://" + Figaro.env.DATASTORE_HOST +
    logger.info '0. Fetching latest transitland-feed-registry'
    TransitlandClient::FeedRegistry.repo(force_update: true)

    logger.info '1. Checking for new feeds'
    python = './virtualenv/bin/python'
    feedids = `#{python} ./lib/feedeater/check.py #{feed_onestop_ids.join(' ')}`
    if feedids
      feedids = feedids.split()
    else
      feedids = []
    end
    logger.info " -> #{feedids.join(' ')}"
    if feedids.length == 0
      return
    end
  
    # TODO: Child jobs
    for feed in feedids
      logger.info "2. Downloading feed: #{feed}"
      system "#{python} ./lib/feedeater/fetch.py #{feed}"

      logger.info "3. Validating feed: #{feed}"
      system "#{python} ./lib/feedeater/validate.py #{feed}"
    
      logger.info "4. Uploading feed: #{feed}"
      system "#{python} ./lib/feedeater/post.py #{feed}"

      logger.info "5. Creating GTFS artifact: #{feed}"
      system "#{python} ./lib/feedeater/artifact.py #{feed}"

      # logger.info '6. Creating FeedEater Reports'
      # logger.info '7. Uploading to S3'
      # aws s3 sync . s3://onestop-feed-cache.transit.land
    end
    
  end
end
