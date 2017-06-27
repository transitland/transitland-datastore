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
    feed = feed_from_gtfs(@gtfs, url: @url)
    feed = Feed.find_by_onestop_id(feed.onestop_id) || Feed.find_by(url: @url) || feed
    # TODO: Merge created & found feeds?
    # operators
    operators = []
    @gtfs.agencies.each do |agency|
      next if agency.stops.size == 0
      operator = operator_from_gtfs(agency)
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

  private

  # Moved from Feed.from_gtfs
  def feed_from_gtfs(entity, attrs={})
    # Entity is a feed.
    visited_stops = Set.new
    entity.agencies.each { |agency| visited_stops |= agency.stops }
    coordinates = Stop::GEOFACTORY.collection(
      visited_stops.map { |stop| Stop::GEOFACTORY.point(*stop.coordinates) }
    )
    geohash = GeohashHelpers.fit(coordinates)
    geometry = RGeo::Cartesian::BoundingBox.create_from_geometry(coordinates)
    # Generate third Onestop ID component
    feed_id = nil
    if entity.file_present?('feed_info.txt')
      feed_info = entity.feed_infos.first
      feed_id = feed_info.feed_id if feed_info
    end
    name_agencies = entity.agencies.select { |agency| agency.stops.size > 0 }.map(&:agency_name).join('~')
    name_url = Addressable::URI.parse(attrs[:url]).host.gsub(/[^a-zA-Z0-9]/, '') if attrs[:url]
    name = feed_id.presence || name_agencies.presence || name_url.presence || 'unknown'
    # Create Feed
    attrs[:geometry] = geometry.to_geometry
    attrs[:onestop_id] = OnestopId.handler_by_model(Feed).new(
      geohash: geohash,
      name: name
    )
    feed = Feed.new(attrs)
    feed.tags ||= {}
    feed.tags[:feed_id] = feed_id if feed_id
    feed
  end

  # Moved from Operator.from_gtfs
  def operator_from_gtfs(entity, attrs={})
    # GTFS Constructor
    # Convert to TL Stops so geometry projection works properly...
    tl_stops = entity.stops.map { |stop| Stop.new(geometry: Stop::GEOFACTORY.point(*stop.coordinates)) }
    geohash = GeohashHelpers.fit(
      Stop::GEOFACTORY.collection(tl_stops.map { |stop| stop[:geometry] })
    )
    # Generate third Onestop ID component
    name = [entity.agency_name, entity.id, "unknown"]
      .select(&:present?)
      .first
    # Create Operator
    attrs[:geometry] = Operator.convex_hull(tl_stops, projected: false)
    attrs[:name] = name
    attrs[:onestop_id] = OnestopId.handler_by_model(Operator).new(
      geohash: geohash,
      name: name
    )
    operator = Operator.new(attrs)
    operator.tags ||= {}
    operator.tags[:agency_phone] = entity.agency_phone
    operator.tags[:agency_lang] = entity.agency_lang
    operator.tags[:agency_fare_url] = entity.agency_fare_url
    operator.tags[:agency_id] = entity.id
    operator.tags[:agency_email] = entity.agency_email
    operator.timezone = entity.agency_timezone
    operator.website = entity.agency_url
    operator
  end

end
