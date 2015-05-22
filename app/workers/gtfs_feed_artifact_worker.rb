class GtfsFeedArtifactWorker
  include Sidekiq::Worker

  PYTHON = './virtualenv/bin/python'

  def perform(feed_onestop_id)
    # TODO: if all stops for this feed have tags[:osm_way_id]
    # probably depends upon doing an identifier search like "gtfs://f-9q9-bayarearapidtransit/s/*"
    logger.info "Creating GTFS artifact for #{feed_onestop_id}"
    run_python_and_return_stdout('./lib/feedeater/artifact.py', feed_onestop_id)
  end

  private

  def run_python_and_return_stdout(file, args)
    `#{PYTHON} #{file} #{args}`
  end
end
