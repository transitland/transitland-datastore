class GTFSImporter
  SHAPE_CHUNK_SIZE = 1_000_000
  STOP_TIME_CHUNK_SIZE = 1_000_000
  IMPORT_CHUNK_SIZE = 1_000

  class Error < StandardError
  end

  def initialize(feed_version)
    @feed_version = feed_version
    @gtfs = @feed_version.open_gtfs
    # mappings
    @agency_ids = {}
    @stop_ids = {}
    @route_ids = {}
    @shape_ids = {}
    @trip_ids = {}
  end

  def import
    t_import = Time.now
    t_parse = Time.now
    log('finding selected entities...')
    # list of agency_ids to import
    log('...agencies')
    selected_agency_ids = Set.new
    default_agency_id = nil
    @gtfs.each_agency do |e|
      default_agency_id ||= e.agency_id
      selected_agency_ids << e.agency_id
    end
    log("...default_agency_id: #{default_agency_id}")
    # agency associated routes
    log('...routes')
    selected_route_ids = Set.new
    @gtfs.each_route do |e|
      e.agency_id ||= default_agency_id
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
    log('...services, pruning trips')
    selected_service_ids = Set.new
    selected_shape_ids = Set.new
    @gtfs.each_trip do |e|
      if trip_stop_counter[e.id] > 0
        selected_service_ids << e.service_id
        selected_shape_ids << e.shape_id if e.shape_id
      else
        selected_trip_ids.delete(e.id)
      end
    end
    # shapes
    log('...shapes')
    shape_counter = Hash.new { |h,k| h[k] = 0 }
    if @gtfs.file_present?('shapes.txt')
      @gtfs.each_shape do |e|
        next unless selected_shape_ids.include?(e.shape_id)
        shape_counter[e.shape_id] += 1
      end
    end
    # Fares and transfers
    log("...time: #{((Time.now-t_parse).round(2))}")
    # Import
    time('agencies') { import_agencies(selected_agency_ids) }
    time('stops') { import_stops(selected_stop_ids) }
    time('routes') { import_routes(selected_route_ids, default_agency_id) }
    time('calendar') { import_calendar(selected_service_ids) }
    time('calendar_dates') { import_calendar_dates(selected_service_ids) }
    time('feed_info') { import_feed_info }
    time('fare_rules') { import_fare_rules }
    time('fare_attribtes') { import_fare_attributes(default_agency_id) }
    time('transfers') { import_transfers }
    time('shapes') { import_shapes(shape_counter) }
    time('trips_and_stop_times') { import_trips_and_stop_times(trip_stop_counter) }
    time('frequency') { import_frequency }
    # Done
    log("total: #{((Time.now-t_import).round(2))}")
  end

  def import_agencies(selected_agency_ids=nil)
    @gtfs.each_agency do |agency|
      next if (selected_agency_ids && !selected_agency_ids.include?(agency.id))
      params = {}
      params[:feed_version_id] = @feed_version.id
      params[:agency_id] = agency.agency_id || "" # use empty string for null
      params[:agency_name] = agency.agency_name
      params[:agency_url] = agency.agency_url
      params[:agency_timezone] = agency.agency_timezone
      params[:agency_lang] = agency.agency_lang
      params[:agency_phone] = agency.agency_phone
      params[:agency_fare_url] = agency.agency_fare_url
      params[:agency_email] = agency.agency_email
      create(GTFSAgency.new(params), agency.agency_id, @agency_ids)
    end
  end

  def import_stops(selected_stop_ids=nil)
    parent_ids = {}
    f = GTFSStop.geofactory
    @gtfs.each_stop do |stop|
      next if (selected_stop_ids && !selected_stop_ids.include?(stop.id))
      params = {}
      params[:feed_version_id] = @feed_version.id
      params[:stop_id] = stop.stop_id
      params[:stop_code] = stop.stop_code
      params[:stop_name] = stop.stop_name
      params[:stop_desc] = stop.stop_desc
      params[:stop_url] = stop.stop_url
      params[:zone_id] = stop.zone_id
      params[:location_type] = gtfs_int(stop.location_type) || 0
      params[:stop_timezone] = stop.stop_timezone
      params[:wheelchair_boarding] = gtfs_int(stop.wheelchair_boarding) || 0
      params[:geometry] = f.point(
        gtfs_float(stop.stop_lon),
        gtfs_float(stop.stop_lat)
      )
      create(GTFSStop.new(params), stop.stop_id, @stop_ids)
      parent_ids[stop.stop_id] = stop.parent_station if stop.parent_station.presence
    end
    # Link parent_stations
    parent_ids.each do |stop_id,parent_station|
      next unless @stop_ids[stop_id] && @stop_ids[parent_station]
      GTFSStop.where(id: @stop_ids[stop_id]).update_all(parent_station_id: @stop_ids[parent_station])
    end
  end

  def import_routes(selected_route_ids=nil, default_agency_id=nil)
    @gtfs.each_route do |route|
      next if (selected_route_ids && !selected_route_ids.include?(route.id))
      next unless @agency_ids[route.agency_id] || @agency_ids[default_agency_id]
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
      params[:agency_id] = @agency_ids[route.agency_id] || @agency_ids[default_agency_id]
      create(GTFSRoute.new(params), route.route_id, @route_ids)
    end
  end

  def import_calendar_dates(selected_service_ids=nil)
    return unless @gtfs.file_present?('calendar_dates.txt')
    @gtfs.each_calendar_date do |e|
      next if (selected_service_ids && !selected_service_ids.include?(e.service_id))
      params = {}
      params[:feed_version_id] = @feed_version.id
      params[:service_id] = e.service_id
      params[:date] = gtfs_date(e.date)
      params[:exception_type] = gtfs_int(e.exception_type)
      create(GTFSCalendarDate.new(params))
    end
  end
  
  def import_calendar(selected_service_ids=nil)
    return unless @gtfs.file_present?('calendar.txt')
    @gtfs.each_calendar do |e|
      next if (selected_service_ids && !selected_service_ids.include?(e.service_id))
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
      create(GTFSCalendar.new(params))
    end
  end

  def import_frequency
    return unless @gtfs.file_present?('frequency.txt')
    @gtfs.each_frequency do |e|
      next unless @trip_ids[e.trip_id]
      params = {}
      params[:feed_version_id] = @feed_version.id
      params[:start_time] = gtfs_int(e.start_time)
      params[:end_time] = gtfs_int(e.end_time)
      params[:headway_secs] = gtfs_int(e.headway_secs)
      params[:exact_times] = gtfs_int(e.exact_times) || 0
      params[:trip_id] = @trip_ids[e.trip_id]
      create(GTFSFrequency.new(params))
    end
  end

  def import_transfers
    return unless @gtfs.file_present?('transfers.txt')
    @gtfs.each_transfer do |e|
      next unless @stop_ids[e.from_stop_id] && @stop_ids[e.to_stop_id]
      params = {}
      params[:feed_version_id] = @feed_version.id
      params[:transfer_type] = gtfs_int(e.transfer_type) || 0
      params[:min_transfer_time] = gtfs_int(e.min_transfer_time)
      params[:from_stop_id] = @stop_ids[e.from_stop_id]
      params[:to_stop_id] = @stop_ids[e.to_stop_id]
      create(GTFSTransfer.new(params))
    end
  end

  def import_feed_info
    return unless @gtfs.file_present?('feed_info.txt')
    @gtfs.each_feed_info do |e|
      params = {}
      params[:feed_version_id] = @feed_version.id
      params[:feed_publisher_name] = e.feed_publisher_name
      params[:feed_publisher_url] = e.feed_publisher_url
      params[:feed_lang] = e.feed_lang
      params[:feed_start_date] = gtfs_date(e.feed_start_date)
      params[:feed_end_date] = gtfs_date(e.feed_end_date)
      params[:feed_version_name] = e.feed_version
      create(GTFSFeedInfo.new(params))
    end
  end

  def import_fare_rules
    return unless @gtfs.file_present?('fare_rules.txt')
    @gtfs.each_fare_rule do |e|
      next unless @route_ids[e.route_id]
      params = {}
      params[:feed_version_id] = @feed_version.id
      params[:fare_id] = e.fare_id
      params[:contains_id] = e.contains_id
      params[:origin_id] = e.origin_id
      params[:destination_id] = e.destination_id
      params[:route_id] = @route_ids[e.route_id]
      create(GTFSFareRule.new(params))
    end
  end

  def import_fare_attributes(default_agency_id=nil)
    return unless @gtfs.file_present?('fare_attributes.txt')
    @gtfs.each_fare_attribute do |e|
      next unless @agency_ids[e.agency_id] || @agency_ids[default_agency_id]
      params = {}
      params[:feed_version_id] = @feed_version.id
      params[:fare_id] = e.fare_id
      params[:price] = gtfs_float(e.price)
      params[:currency_type] = e.currency_type
      params[:payment_method] = gtfs_int(e.payment_method)
      params[:transfers] = gtfs_int(e.transfers)
      params[:transfer_duration] = gtfs_int(e.transfer_duration)
      params[:agency_id] = @agency_ids[e.agency_id] || @agency_ids[default_agency_id]
      create(GTFSFareAttribute.new(params))
    end
  end

  def import_shapes(shape_counter=nil)
    return unless @gtfs.file_present?('shapes.txt')
    # load shapes in chunks
    f = GTFSShape.geofactory
    yield_chunks(shape_counter, SHAPE_CHUNK_SIZE) do |shape_id_chunk|
      log("processing shape_id_chunks: #{shape_id_chunk.size}")
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
        create(GTFSShape.new(params), shape_line.shape_id, @shape_ids)
      end
    end
  end

  def import_trips_and_stop_times(trip_stop_counter=nil)
    # load trips
    @gtfs.trips 
    # stop_pattern shape_ids
    @stop_pattern_shape_ids = {} 
    # load stop_times in chunks
    yield_chunks(trip_stop_counter, STOP_TIME_CHUNK_SIZE) do |trip_id_chunk|
      log("processing trip_id_chunks: #{trip_id_chunk.size}")
      @gtfs.each_trip_stop_times(trip_id_chunk) do |trip_id, stop_times|
        import_trip(@gtfs.trip(trip_id), stop_times)
      end
    end
  end

  def import_trip(trip, stop_times)
    log("processing trip #{trip.id} stop_times #{stop_times.size}")
    # Create stop_times
    trip_stop_times = []
    stop_times.each_index do |i|
      origin = stop_times[i]
      destination = stop_times[i+1] # last stop is nil
      next unless @stop_ids[origin.stop_id] && (destination.nil? || @stop_ids[destination.stop_id])
      params = {}
      params[:feed_version_id] = @feed_version.id
      params[:stop_sequence] = gtfs_int(origin.stop_sequence)
      params[:stop_headsign] = origin.stop_headsign
      params[:pickup_type] = gtfs_int(origin.pickup_type) || 0
      params[:drop_off_type] = gtfs_int(origin.drop_off_type) || 0
      params[:shape_dist_traveled] = gtfs_float(origin.shape_dist_traveled)
      params[:timepoint] = gtfs_int(origin.timepoint)
      # where
      params[:stop_id] = @stop_ids[origin.stop_id]
      params[:arrival_time] = gtfs_time(origin.arrival_time)
      params[:departure_time] = gtfs_time(origin.departure_time)
      # for convenience
      params[:destination_id] = @stop_ids[destination.stop_id] if destination
      params[:destination_arrival_time] = gtfs_time(destination.arrival_time) if destination
      trip_stop_times << GTFSStopTime.new(params)
    end
    stop_pattern = trip_stop_times.map(&:stop_id)
    # Create trip
    return unless @route_ids[trip.route_id]
    params = {}
    params[:feed_version_id] = @feed_version.id
    params[:trip_id] = trip.trip_id
    params[:service_id] = trip.service_id
    params[:trip_headsign] = trip.trip_headsign
    params[:trip_short_name] = trip.trip_short_name
    params[:direction_id] = gtfs_int(trip.direction_id)
    params[:block_id] = trip.block_id
    params[:wheelchair_accessible] = gtfs_int(trip.wheelchair_accessible) || 0
    params[:bikes_allowed] = gtfs_int(trip.bikes_allowed) || 0
    params[:route_id] = @route_ids[trip.route_id]
    # Generate a shape if one was not provided
    shape_id = @shape_ids[trip.shape_id]
    if shape_id.nil?
      shape_id = @stop_pattern_shape_ids[stop_pattern] || create_shape_from_stop_pattern(stop_pattern).try(:id)
      @stop_pattern_shape_ids[stop_pattern] = shape_id
    end
    params[:shape_id] = shape_id
    # Save trip
    new_trip = create(GTFSTrip.new(params), trip.trip_id, @trip_ids)
    return unless new_trip
    # Assign trip_id to stop_times
    trip_stop_times.each { |i| i.trip_id = new_trip.id }
    # Interpolate stop_times
    GTFSStopTimeInterpolater.interpolate_stop_times(trip_stop_times, shape_id)
    # Save stop_times
    create_chunk(trip_stop_times, 0)
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

  private

  def create_chunk(chunk, chunk_size=nil)
    chunk_size = chunk_size || IMPORT_CHUNK_SIZE
    if chunk.size > chunk_size
      log("   import #{chunk.size}")
      m = chunk.first.class.import(chunk)
      chunk = []
    end
    return chunk
  end

  def create(record, idid=nil, idmap=nil)
    begin
      record.save!
      log("   saved: #{record.class.name} #{record.id}")
    rescue ActiveRecord::RecordInvalid, ActiveRecord::StatementInvalid => e
      log("   failed: #{record.class.name} #{record.as_json}")
      return nil
    end
    idmap[idid] = record.id if idmap
    record
  end

  def debug(msg)
    log(msg)
  end

  def self.debug(msg)
    log(msg)
  end

  def time(msg, &block)
    t = Time.now
    block.call
    log("#{msg}: #{((Time.now-t)).round(2)}s")
  end

  def gtfs_int(value)
    Integer(value) unless value.nil? || value.empty?
  end

  def gtfs_float(value)
    Float(value) unless value.nil? || value.empty?
  end

  def gtfs_time(value)
    # handles nil and empty
    GTFS::WideTime.parse(value).try(:to_seconds)
  end

  def gtfs_date(value)
    Date.parse(value) unless value.nil? || value.empty?
  end

  def gtfs_boolean(value)
    gtfs_int(value) == 1 ? true : false
  end

  def yield_chunks(counter, batchsize)
    chunk = []
    current = 0
    order = counter.sort_by { |k,v| -v }
    order.each do |k,v|
      if (current + v) > batchsize
        yield chunk
        chunk = []
        current = 0
      end
      chunk << k
      current += v
    end
    yield chunk
  end

  def create_shape_from_stop_pattern(stop_pattern)
    q = "SELECT ST_Force3DM(ST_MakeLine(geometry::geometry)) AS geometry FROM (SELECT geometry FROM gtfs_stops INNER JOIN (SELECT unnest,ordinality FROM unnest( ARRAY[#{stop_pattern.join(',')}] ) WITH ORDINALITY) AS unnest ON gtfs_stops.id = unnest ORDER BY ordinality) AS q"    
    geometry = ActiveRecord::Base.connection.exec_query(q).rows.first.first
    params = {}
    params[:feed_version_id] = @feed_version.id
    params[:shape_id] = Random.rand
    params[:geometry] = geometry
    params[:generated] = true
    create(GTFSShape.new(params))
  end
end
