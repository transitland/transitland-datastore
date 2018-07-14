class GTFSImporter
  SHAPE_CHUNK_SIZE = 1_000_000
  STOP_TIME_CHUNK_SIZE = 1_000_000
  IMPORT_CHUNK_SIZE = 1_000

  class Error < StandardError
  end

  def debug(msg)
    log(msg, :debug)
  end

  def self.debug(msg)
    log(msg, :debug)
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
    t_import = Time.now
    time('agencies') { import_agencies }
    time('stops') { import_stops }
    time('routes') { import_routes }
    time('shapes') { import_shapes }
    time('trips') { import_trips }
    time('calendar') { import_calendar }
    time('calendar_dates') { import_calendar_dates }
    time('optional') { import_optional }
    time('stop_times') { import_stop_times }
    log("total: #{((Time.now-t_import).round(2))}")
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
    @gtfs.each_trip do |trip|
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
      params[:shape_id] = @shape_ids[trip.shape_id] # optional
      @trip_ids[trip.trip_id] = GTFSTrip.create!(params).id
    end
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


  def import_stop_times
    total_stop_times = 0
    @gtfs.trip_id_chunks(STOP_TIME_CHUNK_SIZE) do |trip_id_chunk|
      log("processing trip_id_chunks: #{trip_id_chunk}")
      chunk_stop_times = []
      @gtfs.each_trip_stop_times(trip_id_chunk) do |trip_id, stop_times|
        log("stop_times: trip #{trip_id} stop_times #{stop_times.size}")
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
          params[:trip_id] = @trip_ids.fetch(origin.trip_id)
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
        # Interpolate
        self.class.interpolate_stop_times(trip_stop_times)
        # Validate
        if !trip_stop_times.map(&:valid?).all?
          log("invalid stop_times!")
        end
        chunk_stop_times += trip_stop_times
        total_stop_times += trip_stop_times.size
        chunk_stop_times = import_chunk(chunk_stop_times)
      end
      chunk_stop_times = import_chunk(chunk_stop_times, 0)
    end
    log("total stop_times: #{total_stop_times}")
  end

  def import_chunk(chunk, chunk_size=nil)
    chunk_size = chunk_size || IMPORT_CHUNK_SIZE
    if chunk.size > chunk_size
      log("... import #{chunk.size}")
      chunk.first.class.import(chunk)
      chunk = []
    end
    return chunk
  end

  def self.interpolate_stop_times(stop_times)
    stop_times = clean_stop_times(stop_times)
    # Return early if possible
    gaps = interpolate_find_gaps(stop_times)
    return stop_times if gaps.size == 0
    # Measure stops along line
    shape_id = GTFSTrip.find(stop_times.first.trip_id).try(:shape_id)
    trip_pattern = stop_times.map(&:stop_id)
    # First pass: line interpolation
    distances = get_shape_stop_distances(trip_pattern, shape_id)
    gaps.each do |gap|
      o, c = gap
      interpolate_gap_distance(stop_times[o..c], distances)
    end
    # Second pass: distance interpolation
    gaps = interpolate_find_gaps(stop_times)
    gaps.each do |gap|
      o, c = gap
      interpolate_gap_linear(stop_times[o..c])
    end
    return stop_times
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

  def self.get_shape_stop_distances(trip_pattern, shape_id)
    # Calculate line percent from closest point to stop
    distances = {}
    s = 'gtfs_stops.id, ST_LineLocatePoint(shapes.geometry::geometry, ST_ClosestPoint(shapes.geometry::geometry, ST_SetSRID(gtfs_stops.geometry, 4326))) AS line_s'
    g = GTFSStop.select(s)
    # Create shape if necessary
    if shape_id
      g = g.joins('INNER JOIN gtfs_shapes AS shapes ON true')
    else
      shape_id = 0
      g = g.joins("INNER JOIN (SELECT 0 as id, ST_SetSRID(ST_MakeLine(geometry), 4326) AS geometry FROM (SELECT geometry FROM gtfs_stops INNER JOIN (SELECT unnest,ordinality FROM unnest( ARRAY[#{trip_pattern.join(',')}] ) WITH ORDINALITY) as unnest ON gtfs_stops.id = unnest ORDER BY ordinality) as q) AS shapes ON true")
    end
    # Filter
    g = g.where('shapes.id': shape_id, id: trip_pattern)
    # Run
    g.each do |row|
      distances[row.id] = row.line_s
    end
    return distances
  end

  def self.clean_stop_times(stop_times)
    # Sort by stop_sequence
    stop_times.sort_by! { |st| st.stop_sequence }

    # If we only have 1 time, assume it is both arrival and departure
    stop_times.each do |st|
      (st.arrival_time = st.departure_time) if st.arrival_time.nil?
      (st.departure_time = st.arrival_time) if st.departure_time.nil?
    end

    # Ensure time is positive
    current = stop_times.first.arrival_time
    stop_times.each do |st|
      s = st.arrival_time
      fail Exception.new('cannot go backwards in time') if s && s < current
      current = s if s
      s = st.departure_time
      fail Exception.new('cannot go backwards in time') if s && s < current
      current = s if s
    end

    # These two values are required by spec
    fail Exception.new('missing first departure time') if stop_times.first.departure_time.nil?
    fail Exception.new('missing last arrival time') if stop_times.last.arrival_time.nil?
    return stop_times
  end

  def self.interpolate_find_gaps(stop_times)
    gaps = []
    o, c = nil, nil
    stop_times.each_with_index do |st, i|
      # close an open gap
      # puts "i: #{i} st: #{st.stop_sequence} stop: #{st.stop_id} arrival_time: #{st.arrival_time} departure_time: #{st.departure_time}"
      if o && st.arrival_time
        gaps << [o, i] if (i-o > 1)
        o = nil
      end
      # open a new gap
      if o.nil? && st.departure_time
        o = i
      end
    end
    return gaps
  end

  def self.interpolate_gap_distance(stop_times, distances)
    debug("trip: #{stop_times.first.trip_id} interpolate_gap_distance: #{stop_times.first.stop_sequence} -> #{stop_times.last.stop_sequence}")
    # open and close times
    o_time = stop_times.first.departure_time
    c_time = stop_times.last.arrival_time
    # open and close distances
    o_distance = distances[stop_times.first.stop_id]
    c_distance = distances[stop_times.last.stop_id]
    # check that we can interpolate reasonably
    p_distance = o_distance
    stop_times.each do |st|
      i_distance = distances[st.stop_id]
      return unless i_distance
      return if i_distance < p_distance # cannot backtrack
      return if i_distance > c_distance # cannot exceed end
      p_distance = i_distance
    end
    # interpolate on distance
    debug("\tlength: #{c_distance - o_distance} duration: #{c_time - o_time}")
    debug("\to_distance: #{o_distance} o_time: #{o_time}")
    stop_times[1...-1].each do |st|
      i_distance = distances[st.stop_id]
      pct = (i_distance - o_distance) / (c_distance - o_distance)
      i_time = (c_time - o_time) * pct + o_time
      debug("\ti_distance: #{i_distance} pct: #{pct} i_time: #{i_time}")
      st.arrival_time = i_time
      st.departure_time = i_time
    end
    debug("\tc_distance: #{c_distance} c_time: #{c_time}")
    return true
  end

  def self.interpolate_gap_linear(stop_times)
    debug("trip: #{stop_times.first.trip_id} interpolate_gap_linear: #{stop_times.first.stop_sequence} -> #{stop_times.last.stop_sequence}")
    # open and close times
    o_time = stop_times.first.departure_time
    c_time = stop_times.last.arrival_time
    # interpolate on time
    p_time = o_time
    debug("\tduration: #{c_time - o_time}")
    debug("\ti: 0 o_time: #{o_time}")
    stop_times[1...-1].each_with_index do |st,i|
      pct = pct = (i+1) / (stop_times.size.to_f-1)
      i_time = (c_time - o_time) * pct + o_time
      debug("\ti: #{i+1} pct: #{pct} i_time: #{i_time} ")
      st.arrival_time = i_time
      st.departure_time = i_time
    end
    debug("\ti: #{stop_times.size-1} c_time: #{c_time}")
  end
end
