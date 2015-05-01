class FeedEaterWorker
  include Sidekiq::Worker

  def perform(feed_onestop_ids: [])
    logger.info '0. fetching latest onestop-id-registry'
    OnestopIdClient::Registry.repo(force_update: true)

    logger.info '1. downloading feeds that have been updated'

    # TODO: datastore_api_base_url = Figaro.env.DATASTORE_PROTOCOL + "://" + Figaro.env.DATASTORE_HOST +

    # 1.1. feedvalidator.py
    # 2. onestop-updater: Merge & POST changesets to Datastore
    system "cd #{Figaro.env.onestop_id_registry_local_path} &&
            python -m onestop_updater.checkfeeds
            #{feed_onestop_ids.join(' ')}"

    # 3. onestop-updater: Write out GTFS+onestop
    # 4. onestop-updater: Push to Amazon S3

    # 5. build report & upload validator output to S3
  end
end
