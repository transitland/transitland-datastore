class FeedInfo

  CACHE_EXPIRATION = 4.hour

  def initialize(url: nil, path: nil)
    fail ArgumentError.new('must provide url') unless url.present?
    @url = url
    @path = path
    @gtfs = nil
  end

  def open(&block)
    if @gtfs
      yield self
    elsif @path
      @gtfs = GTFS::Source.build(@path, {strict: false})
      @gtfs.load_graph
      yield self
    elsif @url
      FeedFetch.download_to_tempfile(@url) do |path|
        @path = path
        @gtfs = GTFS::Source.build(@path, {strict: false})
        @gtfs.load_graph
        yield self
      end
    end
  end

  def parse_feed_and_operators
    # find visited stops
    stop_map = {}
    agency_visited_stops = {}
    feed_visited_stops = Set.new
    @gtfs.agencies.each do |agency|
      visited_stops = Set.new
      @gtfs.children(agency).each do |route|
        @gtfs.children(route).each do |trip|
          @gtfs.children(trip).each do |stop|
            stop_map[stop] ||= Stop.from_gtfs(stop)
            visited_stops << stop_map[stop]
          end
        end
      end
      agency_visited_stops[agency] = visited_stops
      feed_visited_stops |= visited_stops
    end
    # feed
    feed = Feed.from_gtfs(@url, feed_visited_stops)
    # operators
    operators = []
    @gtfs.agencies.each do |agency|
      operator = Operator.from_gtfs(agency, agency_visited_stops[agency])
      operators << operator
      feed.operators_in_feed.new(gtfs_agency_id: agency.id, operator: operator, id: nil)
    end
    # done
    return [feed, operators]
  end
end
