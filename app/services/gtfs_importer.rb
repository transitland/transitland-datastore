class GTFSImporter
  SHAPE_CHUNK_SIZE = 1_000_000
  STOP_TIME_CHUNK_SIZE = 1_000_000
  IMPORT_CHUNK_SIZE = 1_000

  class Error < StandardError
  end

  def debug(msg)
    log(msg)
  end

  def self.debug(msg)
    log(msg)
  end

  def initialize(feed_version)
    @feed_version = feed_version
    @gtfs = @feed_version.open_gtfs
    # mappings
    @agency_ids = {}
    @stop_ids = {}
    @trip_ids = {}
    @route_ids = {}
    @shape_ids = {}
  end

  def clean_start
    GTFSAgency.where(feed_version: @feed_version).delete_all
    GTFSCalendarDate.where(feed_version: @feed_version).delete_all
    GTFSCalendar.where(feed_version: @feed_version).delete_all
    GTFSFareAttribute.where(feed_version: @feed_version).delete_all
    GTFSFareRule.where(feed_version: @feed_version).delete_all
    GTFSFeedInfo.where(feed_version: @feed_version).delete_all
    GTFSFrequency.where(feed_version: @feed_version).delete_all
    GTFSRoute.where(feed_version: @feed_version).delete_all
    GTFSShape.where(feed_version: @feed_version).delete_all
    GTFSStop.where(feed_version: @feed_version).delete_all
    GTFSStopTime.where(feed_version: @feed_version).delete_all
    GTFSTransfer.where(feed_version: @feed_version).delete_all
    GTFSTrip.where(feed_version: @feed_version).delete_all
  end

  def time(msg, &block)
    t = Time.now
    block.call
    log("#{msg}: #{((Time.now-t)).round(2)}")
  end

  def import
    # Import order is important.
    time('import') { import2 }
    binding.pry
    # t_import = Time.now
    # time('agencies') { import_agencies }
    # time('stops') { import_stops }
    # time('routes') { import_routes }
    # time('calendar') { import_calendar }
    # time('calendar_dates') { import_calendar_dates }
    # time('optional') { import_optional }
    # time('shapes') { import_shapes }
    # time('trips_and_stop_times') { import_trips_and_stop_times }
    # log("total: #{((Time.now-t_import).round(2))}")
  end

  def import2
    log('finding selected entities...')
    # list of agency_ids to import
    log('...agencies')
    selected_agency_ids = Set.new # Set.new([@gtfs.agencies.first.id])
    @gtfs.each_agency do |e|
      selected_agency_ids << e.id
    end
    # agency associated routes
    log('...routes')
    selected_route_ids = Set.new
    @gtfs.each_route do |e|
      next unless selected_agency_ids.include?(e.agency_id)
      selected_route_ids << e.id
    end
    # trips associated with selected routes
    log('...trips')
    selected_trip_ids = Set.new
    @gtfs.each_trip do |e|
      next unless selected_route_ids.include?(e.route_id)
      selected_trip_ids << e.id
    end
    # stops associated with selected trips, and trip counter for pruning
    log('...stops')
    selected_stop_ids = Set.new
    trip_stop_counter = Hash.new { |h,k| h[k] = 0 }
    @gtfs.each_stop_time do |e|
      next unless selected_trip_ids.include?(e.trip_id)
      selected_stop_ids << e.stop_id
      trip_stop_counter[e.trip_id] += 1
    end
    # include stop parent_stations
    @gtfs.each_stop do |e|
      next unless selected_stop_ids.include?(e.id)
      selected_stop_ids << e.parent_station if e.parent_station
    end
    # pass through trips again for services and shapes
    log('...services, shapes, pruning trips')
    selected_service_ids = Set.new
    selected_shape_ids = Set.new
    @gtfs.each_trip do |e|
      if trip_stop_counter[e.id] > 0
        selected_service_ids << e.service_id
        selected_shape_ids << e.shape_id
      else
        selected_trip_ids.remove(e.id)
      end
    end
    # fares and transfers
  end

  def import_agencies
    @gtfs.each_agency do |agency|
      params = {}
      params[:feed_version_id] = @feed_version.id
      params[:agency_id] = agency.agency_id
      params[:agency_name] = agency.agency_name
      params[:agency_url] = agency.agency_url
      params[:agency_timezone] = agency.agency_timezone
      params[:agency_lang] = agency.agency_lang
      params[:agency_phone] = agency.agency_phone
      params[:agency_fare_url] = agency.agency_fare_url
      params[:agency_email] = agency.agency_email
      @agency_ids[agency.agency_id] = GTFSAgency.create!(params).id
    end
  end

  def import_stops
    parent_ids = {}
    f = GTFSStop.geofactory
    @gtfs.each_stop do |stop|
      params = {}
      params[:feed_version_id] = @feed_version.id
      params[:stop_id] = stop.stop_id
      params[:stop_code] = stop.stop_code
      params[:stop_name] = stop.stop_name
      params[:stop_desc] = stop.stop_desc
      params[:stop_url] = stop.stop_url
      params[:zone_id] = stop.zone_id
      params[:location_type] = gtfs_int(stop.location_type)
      params[:stop_timezone] = stop.stop_timezone
      params[:wheelchair_boarding] = gtfs_int(stop.wheelchair_boarding)
      params[:geometry] = f.point(
        gtfs_float(stop.stop_lon),
        gtfs_float(stop.stop_lat)
      )
      @stop_ids[stop.stop_id] = GTFSStop.create!(params).id
      parent_ids[stop.stop_id] = stop.parent_station if stop.parent_station.presence
    end
    # Link parent_stations
    parent_ids.each do |stop_id,parent_station|
      GTFSStop.where(id: @stop_ids.fetch(stop_id)).update_all(parent_station_id: @stop_ids.fetch(parent_station))
    end
  end

  def import_routes
    @gtfs.each_route do |route|
      params = {}
      params[:feed_version_id] = @feed_version.id
      params[:route_id] = route.route_id
      params[:route_short_name] = route.route_short_name || "" # spec
      params[:route_long_name] = route.route_long_name || "" # spec
      params[:route_desc] = route.route_desc
      params[:route_type] = gtfs_int(route.route_type)
      params[:route_url] = route.route_url
      params[:route_color] = route.route_color
      params[:route_text_color] = route.route_text_color
      params[:agency_id] = @agency_ids.fetch(route.agency_id || @agency_ids.keys.first)
      @route_ids[route.route_id] = GTFSRoute.create!(params).id
    end
  end

  def import_shapes
    f = GTFSShape.geofactory
    @gtfs.shape_id_chunks(SHAPE_CHUNK_SIZE) do |shape_id_chunk|
      log("processing shape_id_chunks: #{shape_id_chunk}")
      @gtfs.each_shape_line(shape_id_chunk) do |shape_line|
        log("shape_line: #{shape_line.shape_id} shapes #{shape_line.shapes.size}")
        params = {}
        params[:feed_version_id] = @feed_version.id
        params[:shape_id] = shape_line.shape_id
        params[:geometry] = f.line_string(
          shape_line.shapes.map { |s|
            f.point(
              gtfs_float(s.shape_pt_lon),
              gtfs_float(s.shape_pt_lat),
              gtfs_float(s.shape_dist_traveled)
            )
          }
        )
        @shape_ids[shape_line.shape_id] = GTFSShape.create!(params).id
      end
    end
  end

  def import_trips
  end

  def import_calendar_dates
    return unless @gtfs.file_present?('calendar_dates.txt')
    @gtfs.each_calendar_date do |e|
      params = {}
      params[:feed_version_id] = @feed_version.id
      params[:service_id] = e.service_id
      params[:date] = gtfs_date(e.date)
      params[:exception_type] = gtfs_int(e.exception_type)
      GTFSCalendarDate.create!(params)
    end
  end

  def import_calendar
    return unless @gtfs.file_present?('calendar.txt')
    @gtfs.each_calendar do |e|
      params = {}
      params[:feed_version_id] = @feed_version.id
      params[:service_id] = e.service_id
      params[:start_date] = gtfs_date(e.start_date)
      params[:end_date] = gtfs_date(e.end_date)
      params[:monday] = gtfs_boolean(e.monday)
      params[:tuesday] = gtfs_boolean(e.tuesday)
      params[:wednesday] = gtfs_boolean(e.wednesday)
      params[:thursday] = gtfs_boolean(e.thursday)
      params[:friday] = gtfs_boolean(e.friday)
      params[:saturday] = gtfs_boolean(e.saturday)
      params[:sunday] = gtfs_boolean(e.sunday)
      GTFSCalendar.create!(params)
    end
  end

  def import_optional
    # Optional files
    import_frequency
    import_feed_info
    import_transfers
    import_fare_rules
    import_fare_attributes
  end

  def import_frequency
    return unless @gtfs.file_present?('frequency.txt')
  end

  def import_transfers
    return unless @gtfs.file_present?('transfers.txt')
  end

  def import_feed_info
    return unless @gtfs.file_present?('feed_info.txt')
  end

  def import_fare_rules
    return unless @gtfs.file_present?('fare_rules.txt')
  end

  def import_fare_attributes
    return unless @gtfs.file_present?('fare_attributes.txt')
  end

  def import_trips_and_stop_times
    @gtfs.trips # load trips
    @stop_pattern_shape_ids = {} # stop_pattern shape_ids
    @gtfs.trip_id_chunks(STOP_TIME_CHUNK_SIZE) do |trip_id_chunk|
      log("processing trip_id_chunks: #{trip_id_chunk}")
      @gtfs.each_trip_stop_times(trip_id_chunk) do |trip_id, stop_times|
        import_trip_stop_times(@gtfs.trip(trip_id), stop_times)
      end
    end
  end

  def import_trip_stop_times(trip, stop_times)
    log("stop_times: trip #{trip.id} stop_times #{stop_times.size}")
    trip_stop_times = []
    stop_times.each_index do |i|
      origin = stop_times[i]
      destination = stop_times[i+1] # last stop is nil
      params = {}
      params[:feed_version_id] = @feed_version.id
      params[:stop_sequence] = gtfs_int(origin.stop_sequence)
      params[:stop_headsign] = origin.stop_headsign
      params[:pickup_type] = gtfs_int(origin.pickup_type)
      params[:drop_off_type] = gtfs_int(origin.drop_off_type)
      params[:shape_dist_traveled] = gtfs_float(origin.shape_dist_traveled)
      # params[:trip_id] = @trip_ids.fetch(origin.trip_id)
      # params[:timepoint] = gtfs_int(origin.timepoint)
      # where
      params[:stop_id] = @stop_ids.fetch(origin.stop_id)
      params[:arrival_time] = gtfs_time(origin.arrival_time)
      params[:departure_time] = gtfs_time(origin.departure_time)
      # for convenience
      params[:destination_id] = @stop_ids.fetch(destination.stop_id) if destination
      params[:destination_arrival_time] = gtfs_time(destination.arrival_time) if destination
      trip_stop_times << GTFSStopTime.new(params)
    end

    # Create trip
    stop_pattern = trip_stop_times.map(&:stop_id)
    params = {}
    params[:feed_version_id] = @feed_version.id
    params[:trip_id] = trip.trip_id
    params[:service_id] = trip.service_id
    params[:trip_headsign] = trip.trip_headsign
    params[:trip_short_name] = trip.trip_short_name
    params[:direction_id] = gtfs_int(trip.direction_id)
    params[:block_id] = trip.block_id
    params[:wheelchair_accessible] = gtfs_int(trip.wheelchair_accessible)
    params[:bikes_allowed] = gtfs_int(trip.bikes_allowed)
    params[:route_id] = @route_ids.fetch(trip.route_id)
    shape_id = @shape_ids[trip.shape_id]
    if shape_id.nil?
      shape_id = @stop_pattern_shape_ids[stop_pattern] || create_shape_from_stop_pattern(stop_pattern).try(:id)
      @stop_pattern_shape_ids[stop_pattern] = shape_id
    end
    params[:shape_id] = shape_id
    new_trip = GTFSTrip.create!(params)

    # Assign trip_ids
    trip_stop_times.each { |i| i.trip_id = new_trip.id }

    # Interpolate stop_times
    GTFSStopTimeInterpolater.interpolate_stop_times(trip_stop_times, shape_id)

    # Validate
    if !trip_stop_times.map(&:valid?).all?
      log("invalid stop_times!")
    end
    import_chunk(trip_stop_times)
  end

  def import_chunk(chunk, chunk_size=nil, idmap=nil)
    chunk_size = chunk_size || IMPORT_CHUNK_SIZE
    if chunk.size > chunk_size
      log("... import #{chunk.size}")
      m = chunk.first.class.import(chunk)
      chunk = []
    end
    return chunk
  end

  private

  def gtfs_int(value)
    Integer(value) unless value.nil? || value.empty?
  end

  def gtfs_float(value)
    Float(value) unless value.nil? || value.empty?
  end

  def gtfs_time(value)
    # handles nil and empty
    GTFS::WideTime.parse(value).to_seconds
  end

  def gtfs_date(value)
    Date.parse(value) unless value.nil? || value.empty?
  end

  def gtfs_boolean(value)
    gtfs_int(value) == 1 ? true : false
  end

  def create_shape_from_stop_pattern(stop_pattern)
    q = "SELECT ST_Force3DM(ST_MakeLine(geometry::geometry)) AS geometry FROM (SELECT geometry FROM gtfs_stops INNER JOIN (SELECT unnest,ordinality FROM unnest( ARRAY[#{stop_pattern.join(',')}] ) WITH ORDINALITY) AS unnest ON gtfs_stops.id = unnest ORDER BY ordinality) AS q"    
    geometry = ActiveRecord::Base.connection.exec_query(q).rows.first.first
    GTFSShape.create!(shape_id: Random.rand, geometry: geometry, generated: true, feed_version: @feed_version)
  end
end
