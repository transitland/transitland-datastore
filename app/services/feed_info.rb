class FeedInfo

  CACHE_EXPIRATION = Float(Figaro.env.feed_info_cache_expiration.presence || 14400)

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
    # feed
    feed = Feed.from_gtfs(@gtfs, url: @url)
    # operators
    operators = []
    @gtfs.agencies.each do |agency|
      next if agency.stops.size == 0
      operator = Operator.from_gtfs(agency)
      operators << operator
      feed.includes_operators ||= []
      feed.includes_operators << {gtfsAgencyId: agency.id, operatorOnestopId: operator.onestop_id}
      feed.operators_in_feed.new(gtfs_agency_id: agency.id, operator: operator, id: nil)
    end
    # done
    return [feed, operators]
  end
end
