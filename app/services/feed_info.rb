class FeedInfo

  CACHE_EXPIRATION = Float(Figaro.env.feed_info_cache_expiration.presence || 14400)

  def initialize(url: nil, path: nil)
    fail ArgumentError.new('must provide url') unless url.present?
    @url = url.to_s.strip
    @path = path
    @gtfs = nil
  end

  def download(progress: nil, &block)
    FeedFetch.download_to_tempfile(@url, progress: progress) do |path|
      @path = path
      block.call self
    end
  end

  def process(progress: nil, &block)
    @gtfs = GTFS::Source.build(@path, {strict: false})
    @gtfs.load_graph(&progress)
    block.call self
  end

  def open(&block)
    if @gtfs
      block.call self
    elsif @path
      process { |i| open(&block) }
    elsif @url
      download { |i| open(&block) }
    end
  end

  def parse_feed_and_operators
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
