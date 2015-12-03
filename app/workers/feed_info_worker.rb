class FeedInfoWorker
  include Sidekiq::Worker

  def perform(url, cachekey)
    file = Tempfile.new('test.zip', Dir.tmpdir, 'wb+')
    file.binmode
    begin
      response = Faraday.get(url)
      file.write(response.body)
      file.close
      feed, operators = gtfs_feed_operators(file.path)
    ensure
      file.close
      file.unlink
    end
    feed.url = url
    data = {
      status: 'complete',
      url: url,
      feed: FeedSerializer.new(feed).as_json,
      operators: operators.map { |o| OperatorSerializer.new(o).as_json }
    }
    sleep 5
    Rails.cache.write(cachekey, data)
  end

  def gtfs_feed_operators(filename)
    gtfs = GTFS::Source.build(filename, {strict: false})
    gtfs.load_graph
    stop_map = {}
    gtfs.stops.each do |stop|
      stop_map[stop] = Stop.from_gtfs(stop)
    end
    feed = Feed.from_gtfs(nil, stop_map.values)
    operators = []
    gtfs.agencies.each do |agency|
      agency_stops = Set.new
      gtfs.children(agency).each do |route|
        gtfs.children(route).each do |trip|
          gtfs.children(trip).each do |stop|
            agency_stops << stop_map[stop]
          end
        end
      end
      operator = Operator.from_gtfs(agency, agency_stops)
      operators << operator
      feed.operators_in_feed.new(gtfs_agency_id: agency.id, operator: operator, id: nil)
    end
    return [feed, operators]
  end
end
