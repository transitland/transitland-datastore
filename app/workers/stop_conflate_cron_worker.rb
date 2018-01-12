class StopConflateCronWorker
  include Sidekiq::Worker
  def perform
    Stop.re_conflate_with_osm
  end
end
