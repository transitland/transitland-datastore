class FeedEaterWorker
  include Sidekiq::Worker

  def perform(feed_onestop_ids: [])
    logger.info '0. fetching latest onestop-id-registry'
    OnestopIdClient::Registry.repo(force_update: true)

    logger.info '1. downloading feeds that have been updated'
    # system "cd #{Figaro.env.onestop_id_registry_local_path} &&
    #         python -m onestop_updater.checkfeeds
    #         #{feed_onestop_ids.join(' ')}"
    system "python -m feedeater.fetch #{feed_onestop_ids.join(' ')}"

    # 1.1. feedvalidator.py
    system "python -m feedeater.validate #{feed_onestop_ids.join(' ')}"
    
    # 2. onestop-updater: Merge & POST changesets to Datastore
    # TODO: datastore_api_base_url = Figaro.env.DATASTORE_PROTOCOL + "://" + Figaro.env.DATASTORE_HOST +
    system "pythom -m feedeater.post #{feed_onestop_ids.join(' ')}"

    # 3. onestop-updater: Write out GTFS+onestop
    system "python -m feedeater.merge #{feed_onestop_ids.join(' ')}"
  
    # 3.1: feedeater reports
  
    # 4. onestop-updater: Push to Amazon S3
    # aws sync

    # 5. build report & upload validator output to S3
  end
end
