class ConflateStopsWithOsmWorker
  include Sidekiq::Worker

  def perform(stop_ids: [])
    stops = Stop.where(id: stop_ids)
    stops.each do |stop|
      stop.conflate_with_osm
    end
  end
end
