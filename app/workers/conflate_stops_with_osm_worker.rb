class ConflateStopsWithOsmWorker
  include Sidekiq::Worker

  def perform(stop_ids = [])
    stops = Stop.where(id: stop_ids).find_in_batches(batch_size: 1000) do |batch_of_stops|
      Stop.conflate_with_osm(batch_of_stops)
    end
  end
end
