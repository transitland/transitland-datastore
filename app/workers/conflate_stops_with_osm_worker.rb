class ConflateStopsWithOsmWorker
  include Sidekiq::Worker

  def perform(stop_ids = [])
    stops = Stop.where(id: stop_ids)
    Stop.conflate_with_osm(stops)
  end
end
