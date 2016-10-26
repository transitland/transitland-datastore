class GTFSGraph

  class Error < StandardError
  end

  attr_accessor :feed, :feed_version

  CHANGE_PAYLOAD_MAX_ENTITIES = Figaro.env.feed_eater_change_payload_max_entities.try(:to_i) || 1_000
  STOP_TIMES_MAX_LOAD = Figaro.env.feed_eater_stop_times_max_load.try(:to_i) || 100_000


  def self.to_trips_accessible(trips, key)
    # All combinations of 0,1,2 to:
    #    [:some_trips, :all_trips, :no_trips, :unknown]
    values = trips.map { |trip| trip.send(key).to_i }.to_set
    if values == Set.new([0])
      :unknown
    elsif values == Set.new([1])
      :all_trips
    elsif values == Set.new([2])
      :no_trips
    elsif values.include?(1)
      :some_trips
    else
      :no_trips
    end
  end

  def self.to_tfn(value)
    case value.to_i
    when 0
      nil
    when 1
      true
    when 2
      false
    end
  end

  def self.to_pickup_type(value)
    case value.to_i
    when 0
      nil
    when 1
      :unavailable
    when 2
      :ask_agency
    when 3
      :ask_driver
    end
  end

  def initialize(feed, feed_version)
    # GTFS Graph / TransitLand wrapper
    @feed = feed
    @feed_version = feed_version
    @gtfs = @feed_version.open_gtfs

    @log = []
    # GTFS entity to Onestop ID
    @gtfs_to_onestop_id = {}
    # TL Indexed by Onestop ID
    @onestop_id_to_entity = {}
  end

  def cleanup
    graph_log "Cleanup any existing FeedVersion SSPs"
    @feed_version.delete_schedule_stop_pairs!
  end

  def create_change_osr
    graph_log "Load GTFS"
    @gtfs.load_graph

    # Lookup frequencies.txt
    @gtfs_frequencies = {}
    if @gtfs.file_present?('frequencies.txt')
      @gtfs_frequencies = @gtfs.frequencies.group_by(&:trip_id)
    end

    graph_log "Load TL"
    load_tl_stops
    load_tl_transfers
    load_tl_routes
    rsps = load_tl_route_stop_patterns
    calculate_rsp_distances(rsps)
    operators = load_tl_operators
    fail GTFSGraph::Error.new('No agencies found that match operators_in_feed') unless operators.size > 0

    # Routes
    routes = operators.map(&:serves).reduce(Set.new, :+).map { |i| find_by_onestop_id(i) }

    # Stops and Platforms
    stops = Set.new
    routes.each { |route| route.serves.each { |stop_onestop_id|
      stop = find_by_onestop_id(stop_onestop_id)
      stops << stop
      stops << stop.parent_stop if stop.parent_stop
    }}

    # Update route geometries
    rsps = rsps.select { |rsp| routes.include?(rsp.route) }
    route_rsps = {}
    rsps.each do |rsp|
      route_rsps[rsp.route] ||= Set.new
      route_rsps[rsp.route] << rsp
    end
    routes.each do |route|
      route.geometry = Route::GEOFACTORY.multi_line_string(
        (route_rsps[route] || []).map { |rsp|
          Route::GEOFACTORY.line_string(
            rsp.geometry[:coordinates].map { |lon, lat| Route::GEOFACTORY.point(lon, lat) }
          )
        }
      )
    end
    ####
    graph_log "Create changeset"
    changeset = Changeset.create(
      imported_from_feed: @feed,
      imported_from_feed_version: @feed_version,
      notes: "Changeset created by FeedEaterWorker for #{@feed.onestop_id} #{@feed_version.sha1}"
    )
    graph_log "Create: Operators, Stops, Routes"
    # Update Feed Bounding Box
    graph_log "  updating feed bounding box"
    @feed.set_bounding_box_from_stops(stops)
    # FIXME: Run through changeset
    @feed.save!
    # Clear out serves; can't find routes that don't exist yet.
    operators.each { |operator| operator.serves = nil }
    graph_log "  operators: #{operators.size}"
    begin
      changeset.create_change_payloads(operators)
      graph_log "  stops: #{stops.size}"
      changeset.create_change_payloads(stops.partition { |i| i.type != 'StopPlatform' }.flatten)
      graph_log "  routes: #{routes.size}"
      changeset.create_change_payloads(routes)
      graph_log "  route geometries: #{rsps.size}"
      changeset.create_change_payloads(rsps)
    rescue Changeset::Error => e
      graph_log "Changeset Error: #{e}"
      graph_log "Payload:"
      graph_log e.payload.to_json
      raise e
    rescue StandardError => e
      graph_log "Error: #{e}"
      raise e
    end
    graph_log "Changeset apply"
    t = Time.now
    changeset.apply!
    graph_log "  apply done: time #{Time.now - t}"
  end

  def calculate_rsp_distances(rsps)
    graph_log "Calculating distances"
    rsps.each do |rsp|
      stops = rsp.stop_pattern.map { |onestop_id| find_by_onestop_id(onestop_id) }
      begin
        rsp.calculate_distances(stops=stops)
      rescue StandardError
        graph_log "Could not calculate distances for Route Stop Pattern: #{rsp.onestop_id}"
        rsp.fallback_distances(stops=stops)
      end
    end
  end

  def ssp_schedule_async
    agency_map, route_map, stop_map, rsp_map = make_gtfs_id_map
    @gtfs.trip_chunks(STOP_TIMES_MAX_LOAD) do |trips|
      trip_ids = trips.map(&:id)
      yield trip_ids, agency_map, route_map, stop_map, rsp_map
    end
  end

  def ssp_perform_async(gtfs_trip_ids, agency_map, route_map, stop_map, rsp_map)
    graph_log "Load GTFS"
    @gtfs.agencies
    @gtfs.routes
    @gtfs.stops
    @gtfs.trips
    load_gtfs_id_map(agency_map, route_map, stop_map, rsp_map)
    gtfs_trips = gtfs_trip_ids.map { |gtfs_trip_id| @gtfs.trip(gtfs_trip_id) }
    graph_log "Create: SSPs"
    total = 0
    ssps = []
    @gtfs.trip_stop_times(trips=gtfs_trips, filter_empty=true) do |gtfs_trip,gtfs_stop_times|
      # Process frequencies
      (@gtfs_frequencies[gtfs_trip.trip_id] || [nil]).each do |gtfs_frequency|
        # Make SSPs for trip
        ssp_trip = self.make_ssp_trip(gtfs_trip, gtfs_stop_times, gtfs_frequency: gtfs_frequency)
        # Interpolate stop_times
        ScheduleStopPair.interpolate(ssp_trip)
        # Add to chunk
        ssps += ssp_trip
      end

      # If chunk is big enough, create change payloads.
      if ssps.size >= CHANGE_PAYLOAD_MAX_ENTITIES
        graph_log  "  ssps: #{ssps.size}"
        fail GTFSGraph::Error.new('Validation error') unless ssps.map(&:valid?).all?
        ScheduleStopPair.import ssps, validate: false
        ssps = []
      end
    end
    if ssps.size > 0
      graph_log  "  ssps: #{ssps.size}"
      fail GTFSGraph::Error.new('Validation error') unless ssps.map(&:valid?).all?
      ScheduleStopPair.import ssps, validate: false
      ssps = []
    end
  end

  def make_ssp_trip(gtfs_trip, gtfs_stop_times, gtfs_frequency: nil)
    # Lookup tl_route from gtfs_trip.route_id
    gtfs_route = @gtfs.route(gtfs_trip.route_id)
    tl_route = find_by_gtfs_entity(gtfs_route)
    unless tl_route
      graph_log "Trip #{gtfs_trip.trip_id}: Missing Route: #{@gtfs_to_onestop_id[gtfs_route]}"
      return []
    end
    # Lookup tl_rsp from gtfs_trip.trip_id
    tl_rsp = find_by_gtfs_entity(gtfs_trip)
    unless tl_rsp
      graph_log "Trip #{gtfs_trip.trip_id}: Missing RouteStopPattern"
      return []
    end
    # Lookup gtfs_service_period from gtfs_trip.service_id
    gtfs_service_period = @gtfs.service_period(gtfs_trip.service_id)
    unless gtfs_service_period
      graph_log "Trip #{gtfs_trip.trip_id}: Unknown GTFS ServicePeriod: #{gtfs_trip.service_id}"
      return []
    end

    # Lookup last stop for fallback Headsign
    last_stop_name = @gtfs.stop(gtfs_stop_times.last.stop_id).stop_name

    # Create SSPs for all gtfs_stop_time edges
    ssp_trip = []
    gtfs_stop_times[0..-2].each_index do |i|
      gtfs_origin_stop_time = gtfs_stop_times[i]
      gtfs_destination_stop_time = gtfs_stop_times[i+1]
      # Get the tl_origin_stop and tl_destination_stop from gtfs_stop_time edge
      gtfs_origin_stop = @gtfs.stop(gtfs_origin_stop_time.stop_id)
      tl_origin_stop = find_by_gtfs_entity(gtfs_origin_stop)
      unless tl_origin_stop
        graph_log "Trip #{gtfs_trip.trip_id}: Missing Stop: #{@gtfs_to_onestop_id[gtfs_origin_stop]}"
        next
      end
      gtfs_destination_stop = @gtfs.stop(gtfs_destination_stop_time.stop_id)
      tl_destination_stop = find_by_gtfs_entity(gtfs_destination_stop)
      unless tl_destination_stop
        graph_log "Trip #{gtfs_trip.trip_id}: Missing Stop: #{@gtfs_to_onestop_id[gtfs_destination_stop]}"
        next
      end

      # Create SSP
      ssp_trip << ScheduleStopPair.new(
        # Feed
        feed: @feed,
        feed_version: @feed_version,
        # Origin
        origin: tl_origin_stop,
        origin_timezone: tl_origin_stop.timezone,
        origin_arrival_time: gtfs_origin_stop_time.arrival_time.presence,
        origin_departure_time: gtfs_origin_stop_time.departure_time.presence,
        origin_dist_traveled: tl_rsp.stop_distances[i],
        # Destination
        destination: tl_destination_stop,
        destination_timezone: tl_destination_stop.timezone,
        destination_arrival_time: gtfs_destination_stop_time.arrival_time.presence,
        destination_departure_time: gtfs_destination_stop_time.departure_time.presence,
        destination_dist_traveled: tl_rsp.stop_distances[i+1],
        # Route
        route: tl_route,
        route_stop_pattern: tl_rsp,
        # Operator
        operator: tl_route.operator,
        # Trip
        trip: gtfs_trip.trip_id,
        trip_headsign: (gtfs_origin_stop_time.stop_headsign || gtfs_trip.trip_headsign || last_stop_name).presence,
        trip_short_name: gtfs_trip.trip_short_name.presence,
        shape_dist_traveled: gtfs_destination_stop_time.shape_dist_traveled.to_f,
        block_id: gtfs_trip.block_id,
        # Accessibility
        pickup_type: self.class.to_pickup_type(gtfs_origin_stop_time.pickup_type),
        drop_off_type: self.class.to_pickup_type(gtfs_destination_stop_time.drop_off_type),
        wheelchair_accessible: self.class.to_tfn(gtfs_trip.wheelchair_accessible),
        bikes_allowed: self.class.to_tfn(gtfs_trip.bikes_allowed),
        # service period
        service_start_date: gtfs_service_period.start_date,
        service_end_date: gtfs_service_period.end_date,
        service_days_of_week: gtfs_service_period.iso_service_weekdays,
        service_added_dates: gtfs_service_period.added_dates,
        service_except_dates: gtfs_service_period.except_dates,
        # frequency
        frequency_start_time: gtfs_frequency.try(:start_time),
        frequency_end_time: gtfs_frequency.try(:end_time),
        frequency_headway_seconds: gtfs_frequency.try(:headway_secs),
        frequency_exact_times: gtfs_frequency.try(:exact_times)
      )
    end
    ssp_trip
  end

  def import_log
    @log.join("\n")
  end

  ##### Private methods #####

  private

  ##### Logging #####

  def graph_log(msg)
    @log << msg
    log(msg)
  end

  ##### Create TL Entities #####

  def load_tl_stops
    # Merge child stations into parents
    graph_log "  stops"
    gtfs_platforms, gtfs_stops = @gtfs.stops.partition { |i| i.parent_station.presence }
    # Create parent stops first
    gtfs_stops.each do |gtfs_stop|
      stop = find_and_update_entity(Stop.from_gtfs(gtfs_stop))
      add_identifier(stop, 's', gtfs_stop)
      graph_log "    Stop: #{stop.onestop_id}: #{stop.name}"
    end
    # Create child stops
    gtfs_platforms.each do |gtfs_stop|
      stop = StopPlatform.from_gtfs(gtfs_stop)
      parent_stop = find_by_gtfs_entity(@gtfs.stop(gtfs_stop.parent_station))
      # Combine onestop_id with parent_stop onestop_id, if present
      if parent_stop
        # parse parent_stop osid
        osid = OnestopId::StopOnestopId.new(string: parent_stop.onestop_id)
        # add gtfs_stop.stop_id as the platform suffix
        stop.onestop_id = OnestopId::StopOnestopId.new(geohash: osid.geohash, name: "#{osid.name}<#{gtfs_stop.id}")
        # add parent_station osid
        stop.parent_stop = parent_stop
      end
      # index
      stop = find_and_update_entity(stop)
      add_identifier(stop, 's', gtfs_stop)
      graph_log "    StopPlatform: #{stop.onestop_id}: #{stop.name}"
    end
  end

  def load_tl_transfers
    # return unless @gtfs.file_present?('transfers.txt')
    # @gtfs.transfers.each do |transfer|
    #   stop = find_by_gtfs_entity(@gtfs.stop(transfer.from_stop_id))
    #   to_stop = find_by_gtfs_entity(@gtfs.stop(transfer.to_stop_id))
    #   next unless stop && to_stop
    #   stop.includes_stop_transfers ||= []
    #   stop.includes_stop_transfers << {
    #     toStopOnestopId: to_stop.onestop_id,
    #     transferType: StopTransfer::GTFS_TRANSFER_TYPE[transfer.transfer_type.presence || "0"],
    #     minTransferTime: transfer.min_transfer_time.to_i
    #   }
    # end
  end

  def load_tl_operators
    # Operators
    graph_log "  operators"
    operators = Set.new
    # key=nil is poorly defined in gtfs wrapper
    agencies = Hash[@gtfs.agencies.map { |a| [a.id,a] }]
    @feed.operators_in_feed.each do |oif|
      entity = agencies[oif.gtfs_agency_id]
      # Skip Operator if not found
      if entity.nil?
        graph_log "    #{oif.operator.onestop_id}: Skipping, GTFS agency_id #{oif.gtfs_agency_id} not found."
        next
      end
      # Skip if no stops
      if entity.stops.empty?
        graph_log "    #{oif.operator.onestop_id}: Skipping, GTFS agency_id #{oif.gtfs_agency_id} has no stops."
        next
      end
      # Create Operator from GTFS
      operator = Operator.from_gtfs(entity)
      operator.onestop_id = oif.operator.onestop_id # Override Onestop ID
      operator_original = operator # for merging geometry
      # ... or check if Operator exists, or another local Operator, or new.
      operator = find_by_entity(operator)
      # Merge convex hulls
      operator[:geometry] = Operator.convex_hull([operator, operator_original], as: :wkt, projected: false)

      # Operator routes & stops
      routes = entity.routes.map { |route| find_by_gtfs_entity(route) }.compact.to_set
      # Find: (tl routes) to (serves tl stops)
      stops = Set.new
      routes.each { |route| route.serves.each { |stop_onestop_id|
        stop = find_by_onestop_id(stop_onestop_id)
        stops << stop
        stops << stop.parent_stop if stop.parent_stop
      }}
      # Copy Operator timezone to fill missing Stop timezones
      stops.each { |stop| stop.timezone = stop.timezone.presence || operator.timezone }
      # Add references and identifiers
      routes.each { |route| route.operated_by = operator.onestop_id }
      operator.serves ||= Set.new
      operator.serves |= routes.map(&:onestop_id)
      add_identifier(operator, 'o', entity)

      # Add to found operators
      operators << operator
      graph_log "    #{operator.onestop_id}: #{operator.name}"
    end
    # Return operators
    operators
  end

  def load_tl_routes
    # Routes
    graph_log "  routes"
    @gtfs.routes.each do |entity|
      # Find: (child gtfs trips) to (child gtfs stops) to (tl stops)
      stops = entity.stops.map { |stop| find_by_gtfs_entity(stop) }.to_set
      # Skip Route if no Stops
      next if stops.empty?
      # Search by similarity
      route = find_and_update_entity(Route.from_gtfs(entity))
      # Update accessibility
      trips = entity.trips
      route.wheelchair_accessible = self.class.to_trips_accessible(trips, :wheelchair_accessible)
      route.bikes_allowed = self.class.to_trips_accessible(trips, :bikes_allowed)
      # Add references and identifiers
      route.serves ||= Set.new
      route.serves |= stops.map(&:onestop_id)
      add_identifier(route, 'r', entity)
      graph_log "    #{route.onestop_id}: #{route.name}"
    end
  end

  def load_tl_route_stop_patterns
    # Route Stop Patterns
    graph_log "  route stop patterns"
    rsps = Set.new
    stop_times_with_shape_dist_traveled = 0
    stop_times_count = 0
    @gtfs.trip_stop_times(trips=nil, filter_empty=true) do |trip,stop_times|
      tl_stops = stop_times.map { |stop_time| find_by_gtfs_entity(@gtfs.stop(stop_time.stop_id)) }
      stop_pattern = tl_stops.map(&:onestop_id)
      stop_times_with_shape_dist_traveled += stop_times.count { |st| !st.shape_dist_traveled.to_s.empty? }
      stop_times_count += stop_times.length
      feed_shape_points = @gtfs.shape_line(trip.shape_id) || []
      tl_route = find_by_gtfs_entity(@gtfs.parents(trip).first)
      # temporary RouteStopPattern
      trip_stop_points = tl_stops.map { |s| s.geometry[:coordinates] }
      # determine if RouteStopPattern exists
      test_rsp = RouteStopPattern.create_from_gtfs(trip, tl_route.onestop_id, stop_pattern, trip_stop_points, feed_shape_points)
      rsp = find_and_update_entity(test_rsp)
      rsp.traversed_by = tl_route.onestop_id
      graph_log "   #{rsp.onestop_id}"  if test_rsp.equal?(rsp)
      unless trip.shape_id.blank?
        identifier = OnestopId::create_identifier(
          @feed.onestop_id,
          'shape',
          trip.shape_id
        )
        rsp.add_identifier(identifier)
      end
      @gtfs_to_onestop_id[trip] = rsp.onestop_id
      rsp.trips << trip.trip_id unless rsp.trips.include?(trip.trip_id)
      rsp.route = tl_route
      rsps << rsp
    end
    graph_log "#{stop_times_with_shape_dist_traveled} stop times with shape_dist_traveled found out of #{stop_times_count} total stop times" if stop_times_with_shape_dist_traveled > 0
    rsps
  end

  def find_by_gtfs_entity(entity)
    find_by_onestop_id(@gtfs_to_onestop_id[entity])
  end

  def find_and_update_entity(entity)
    onestop_id = entity.onestop_id
    cached_entity = @onestop_id_to_entity[onestop_id]
    if cached_entity
      entity = cached_entity
    else
      found_entity = OnestopId.find(onestop_id)
      if found_entity
        found_entity.merge(entity)
        entity = found_entity
      end
    end
    @onestop_id_to_entity[onestop_id] = entity
    entity
  end

  def find_by_entity(entity)
    onestop_id = entity.onestop_id
    entity = @onestop_id_to_entity[onestop_id] || OnestopId.find(onestop_id) || entity
    @onestop_id_to_entity[onestop_id] = entity
    entity
  end

  def find_by_onestop_id(onestop_id)
    # Find and cache a Transitland Entity by Onestop ID
    return nil unless onestop_id
    entity = @onestop_id_to_entity[onestop_id] || OnestopId.find(onestop_id)
    @onestop_id_to_entity[onestop_id] = entity
    entity
  end

  ##### Identifiers #####

  def add_identifier(tl_entity, prefix, gtfs_entity)
    identifier = OnestopId::create_identifier(
      @feed.onestop_id,
      prefix,
      gtfs_entity.id
    )
    tl_entity.add_identifier(identifier)
    @gtfs_to_onestop_id[gtfs_entity] = tl_entity.onestop_id
  end

  def make_gtfs_id_map
    agency_map = {}
    route_map = {}
    stop_map = {}
    rsp_map = {}
    @gtfs.agencies.each { |e| agency_map[e.id] = @gtfs_to_onestop_id[e]}
    @gtfs.routes.each   { |e| route_map[e.id]  = @gtfs_to_onestop_id[e]}
    @gtfs.stops.each    { |e| stop_map[e.id]   = @gtfs_to_onestop_id[e]}
    @gtfs.trips.each    { |e| rsp_map[e.id]    = @gtfs_to_onestop_id[e] unless @gtfs_to_onestop_id[e].blank?}
    [agency_map, route_map, stop_map, rsp_map]
  end

  def load_gtfs_id_map(agency_map, route_map, stop_map, rsp_map)
    @gtfs_to_onestop_id.clear
    @onestop_id_to_entity.clear
    # Populate GTFS entity to Onestop ID maps
    agency_map.each do |agency_id,onestop_id|
      @gtfs_to_onestop_id[@gtfs.agency(agency_id)] = onestop_id
    end
    route_map.each do |route_id,onestop_id|
      @gtfs_to_onestop_id[@gtfs.route(route_id)] = onestop_id
    end
    stop_map.each do |stop_id,onestop_id|
      @gtfs_to_onestop_id[@gtfs.stop(stop_id)] = onestop_id
    end
    rsp_map.each do |trip_id,onestop_id|
      @gtfs_to_onestop_id[@gtfs.trip(trip_id)] = onestop_id
    end
  end
end
