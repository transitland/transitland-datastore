class FeedInfo

  CACHE_EXPIRATION = Float(Figaro.env.feed_info_cache_expiration.presence || 14400)

  attr_accessor :url, :source, :gtfs

  def initialize(url: nil, source: nil, gtfs: nil)
    fail ArgumentError.new('must provide url') unless url.present?
    @url = url.to_s.strip
    @source = source
    @gtfs = gtfs
  end

  def open
    @gtfs ||= GTFS::Source.build(
      @source || @url,
      strict: false,
      tmpdir_basepath: Figaro.env.gtfs_tmpdir_basepath.presence
    )
    yield self
  end

  def parse_feed_and_operators
    # Ensure gtfs graph is loaded
    @gtfs.load_graph
    # feed
    feed = Feed.from_gtfs(@gtfs, url: @url)
    feed = Feed.find_by_onestop_id(feed.onestop_id) || Feed.find_by(url: @url) || feed
    # TODO: Merge created & found feeds?
    # operators
    operators = []
    @gtfs.agencies.each do |agency|
      next if agency.stops.size == 0
      operator = Operator.from_gtfs(agency)
      operator = Operator.find_by_onestop_id(operator.onestop_id) || operator
      operators << operator
      feed.includes_operators ||= []
      feed.includes_operators << {gtfsAgencyId: agency.id, operatorOnestopId: operator.onestop_id}
      feed.operators_in_feed.find_or_initialize_by(
        gtfs_agency_id: agency.id,
        operator: operator
      )
    end
    # done
    return [feed, operators]
  end
end
