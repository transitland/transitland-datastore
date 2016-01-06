class ConflateStopsWithOsmWorker
  include Sidekiq::Worker

  def perform(stop_ids = [])
    Stop.where(id: stop_ids).find_in_batches do |batch_of_stops|
      Stop.conflate_with_osm(batch_of_stops)
    end
  end
end
