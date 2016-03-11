class GTFSGraph

  class Error < StandardError
  end

  CHANGE_PAYLOAD_MAX_ENTITIES = Figaro.env.feed_eater_change_payload_max_entities.try(:to_i) || 1_000
  STOP_TIMES_MAX_LOAD = Figaro.env.feed_eater_stop_times_max_load.try(:to_i) || 100_000

  def initialize(filename, feed, feed_version)
    # GTFS Graph / TransitLand wrapper
    @feed = feed
    @feed_version = feed_version
    @gtfs = GTFS::LocalSource.new(filename, {strict: false})
    @log = []
    # GTFS entity to Onestop ID
    @gtfs_to_onestop_id = {}
    # TL Indexed by Onestop ID
    @onestop_id_to_entity = {}
  end

  def cleanup
    log "Cleanup any existing FeedVersion SSPs"
    @feed_version.delete_schedule_stop_pairs!
  end

  def create_change_osr
    log "Load GTFS"
    @gtfs.load_graph
    log "Load TL"
    load_tl_stops
    load_tl_routes
    rsps = load_tl_route_stop_patterns
    operators = load_tl_operators
    fail GTFSGraph::Error.new('No agencies found that match operators_in_feed') unless operators.size > 0
    routes = operators.map { |operator| operator.serves }.reduce(Set.new, :+)
    stops = routes.map { |route| route.serves }.reduce(Set.new, :+)
    rsps = rsps.select { |rsp| routes.include?(rsp.route) }
    # Update route geometries
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
    log "Create changeset"
    changeset = Changeset.create(
      imported_from_feed: @feed,
      imported_from_feed_version: @feed_version,
      notes: "Changeset created by FeedEaterWorker for #{@feed.onestop_id} #{@feed_version.sha1}"
    )
    log "Create: Operators, Stops, Routes"
    # Update Feed Bounding Box
    log "  updating feed bounding box"
    @feed.set_bounding_box_from_stops(stops)
    # FIXME: Run through changeset
    @feed.save!
    log "  operators: #{operators.size}"
    create_change_payloads(changeset, 'operator', operators.map { |e| make_change_operator(e) })
    log "  stops: #{stops.size}"
    create_change_payloads(changeset, 'stop', stops.map { |e| make_change_stop(e) })
    log "  routes: #{routes.size}"
    create_change_payloads(changeset, 'route', routes.map { |e| make_change_route(e) })
    log "  route geometries: #{rsps.size}"
    create_change_payloads(changeset, 'routeStopPattern', rsps.map { |e| make_change_rsp(e) })
    log "Changeset apply"
    t = Time.now
    changeset.apply!
    changeset.destroy_all_change_payloads
    log "  apply done: time #{Time.now - t}"
  end

  def ssp_schedule_async
    agency_map, route_map, stop_map, rsp_map = make_gtfs_id_map
    @gtfs.trip_chunks(STOP_TIMES_MAX_LOAD) do |trips|
      trip_ids = trips.map(&:id)
      yield trip_ids, agency_map, route_map, stop_map, rsp_map
    end
  end

  def ssp_perform_async(trip_ids, agency_map, route_map, stop_map, rsp_map)
    log "Load GTFS"
    @gtfs.agencies
    @gtfs.routes
    @gtfs.stops
    @gtfs.trips
    load_gtfs_id_map(agency_map, route_map, stop_map, rsp_map)
    trips = trip_ids.map { |trip_id| @gtfs.trip(trip_id) }
    log "Calculating distances"
    rsp_distances_map = {}
    rsps_with_issues = 0
    uniq_rsps = rsp_map.values.uniq
    uniq_rsps.each do |onestop_id|
      rsp = RouteStopPattern.find_by_onestop_id!(onestop_id)
      begin
        rsp_distances_map[onestop_id] = rsp.calculate_distances
        rsp.evaluate_distances(rsp_distances_map[onestop_id])
        rsps_with_issues += 1 if rsp.distance_issues > 0
      rescue StandardError
        log "Could not calculate distances for Route Stop Pattern: #{onestop_id}"
        rsps_with_issues += 1
      end
    end
    score = ((uniq_rsps.size - rsps_with_issues)/uniq_rsps.size.to_f).round(5) rescue score = 1.0
    log "#{rsps_with_issues} Route Stop Patterns out of #{rsp_map.values.uniq.size} had issues with distance calculation. Valhalla Import Score: #{score}"
    log "Create: SSPs"
    total = 0
    ssps = []
    @gtfs.trip_stop_times(trips) do |trip,stop_times|
      route = @gtfs.route(trip.route_id)
      rsp = RouteStopPattern.find_by_onestop_id!(rsp_map[trip.trip_id])
      # Create SSPs for all stop_time edges
      ssp_trip = []
      stop_times[0..-2].each_index do |i|
        origin = stop_times[i]
        destination = stop_times[i+1]
        origin_dist_traveled = nil
        destination_dist_traveled = nil
        if rsp_distances_map.include?(rsp.onestop_id)
          origin_dist_traveled = rsp_distances_map[rsp.onestop_id][i]
          destination_dist_traveled = rsp_distances_map[rsp.onestop_id][i+1]
        end
        ssp_trip << make_ssp(route, trip, origin, origin_dist_traveled, destination, destination_dist_traveled, rsp)
      end
      # Interpolate stop_times
      ScheduleStopPair.interpolate(ssp_trip)
      # Add to chunk
      ssps += ssp_trip
      # If chunk is big enough, create change payloads.
      if ssps.size >= CHANGE_PAYLOAD_MAX_ENTITIES
        log  "  ssps: #{ssps.size}"
        fail GTFSGraph::Error.new('Validation error') unless ssps.map(&:valid?).all?
        ScheduleStopPair.import ssps, validate: false
        ssps = []
      end
    end
    if ssps.size > 0
      log  "  ssps: #{ssps.size}"
      fail GTFSGraph::Error.new('Validation error') unless ssps.map(&:valid?).all?
      ScheduleStopPair.import ssps, validate: false
      ssps = []
    end
  end

  def import_log
    @log.join("\n")
  end

  ##### Private methods #####

  private

  ##### Logging #####

  def log(msg)
    @log << msg
    if Sidekiq::Logging.logger
      Sidekiq::Logging.logger.info msg
    elsif Rails.logger
      Rails.logger.info msg
    else
      puts msg
    end
  end

  ##### Create TL Entities #####

  def load_tl_stops
    # Merge child stations into parents
    log "  stops"
    # Create parent stops first
    @gtfs.stops.reject(&:parent_station).each do |gtfs_stop|
      stop = find_by_entity(Stop.from_gtfs(gtfs_stop))
      add_identifier(stop, 's', gtfs_stop)
      log "    Station: #{stop.onestop_id}: #{stop.name}"
    end
    # Create child stops
    @gtfs.stops.select(&:parent_station).each do |gtfs_stop|
      stop = Stop.from_gtfs(gtfs_stop)
      parent_stop = find_by_gtfs_entity(@gtfs.stop(gtfs_stop.parent_station))
      # Combine onestop_id with parent_stop onestop_id, if present
      if parent_stop
        # parse parent_stop osid
        osid = OnestopId::StopOnestopId.new(string: parent_stop.onestop_id)
        # add gtfs_stop.stop_id as the platform suffix
        stop.onestop_id = OnestopId::StopOnestopId.new(geohash: osid.geohash, name: "#{osid.name}<#{gtfs_stop.id}")
        # add parent_station osid
        stop.tags[:parent_station] = parent_stop.onestop_id
      end
      # index
      stop = find_by_entity(stop)
      add_identifier(stop, 's', gtfs_stop)
      #
      log "    Stop: #{stop.onestop_id}: #{stop.name}"
    end
  end

  def load_tl_operators
    # Operators
    log "  operators"
    operators = Set.new
    # key=nil is poorly defined in gtfs wrapper
    agencies = Hash[@gtfs.agencies.map { |a| [a.id,a] }]
    @feed.operators_in_feed.each do |oif|
      entity = agencies[oif.gtfs_agency_id]
      # Skip Operator if not found
      next unless entity
      # Find: (child gtfs routes) to (tl routes)
      #   note: .compact because some gtfs routes are skipped.
      routes = entity.routes.map { |route| find_by_gtfs_entity(route) }.compact.to_set
      # Find: (tl routes) to (serves tl stops)
      stops = routes
        .map { |route| route.serves }
        .reduce(Set.new, :+)
      # Create Operator from GTFS
      operator = Operator.from_gtfs(entity)
      operator.onestop_id = oif.operator.onestop_id # Override Onestop ID
      operator_original = operator # for merging geometry
      # ... or check if Operator exists, or another local Operator, or new.
      operator = find_by_entity(operator)
      # Merge convex hulls
      operator[:geometry] = Operator.convex_hull([operator, operator_original], as: :wkt, projected: false)
      # Copy Operator timezone to fill missing Stop timezones
      stops.each { |stop| stop.timezone ||= operator.timezone }
      # Add references and identifiers
      routes.each { |route| route.operator = operator }
      operator.serves ||= Set.new
      operator.serves |= routes
      add_identifier(operator, 'o', entity)
      # Cache Operator
      # Add to found operators
      operators << operator
      log "    #{operator.onestop_id}: #{operator.name}"
    end
    # Return operators
    operators
  end

  def load_tl_routes
    # Routes
    log "  routes"
    @gtfs.routes.each do |entity|
      # Find: (child gtfs trips) to (child gtfs stops) to (tl stops)
      stops = entity.stops.map { |stop| find_by_gtfs_entity(stop) }.to_set
      # Also serve parent stations...
      parent_stations = Set.new
      stops.each do |stop|
        parent_station = find_by_onestop_id(stop.tags[:parent_station])
        next unless parent_station
        parent_stations << parent_station
      end
      stops |= parent_stations
      # Skip Route if no Stops
      next if stops.empty?
      # Search by similarity
      # ... or create route from GTFS
      route = Route.from_gtfs(entity)
      # ... check if Route exists, or another local Route, or new.
      route = find_by_entity(route)
      # Add references and identifiers
      route.serves ||= Set.new
      route.serves |= stops
      add_identifier(route, 'r', entity)
      log "    #{route.onestop_id}: #{route.name}"
    end
  end

  def load_tl_route_stop_patterns
    # Route Stop Patterns
    log "  route stop patterns"
    rsps = Set.new
    stop_times_with_shape_dist_traveled = 0
    stop_times_count = 0
    @gtfs.trip_stop_times do |trip,stop_times|
      stop_times_with_shape_dist_traveled += stop_times.count { |st| !st.shape_dist_traveled.to_s.empty?}
      stop_times_count += stop_times.length
      feed_shape_points = @gtfs.shape_line(trip.shape_id) || []
      tl_stops = stop_times.map { |stop_time| find_by_gtfs_entity(@gtfs.stop(stop_time.stop_id)) }
      tl_route = find_by_gtfs_entity(@gtfs.parents(trip).first)
      stop_pattern = tl_stops.map(&:onestop_id)
      next if stop_pattern.empty?
      # temporary RouteStopPattern
      trip_stop_points = tl_stops.map { |s| s.geometry[:coordinates] }
      # determine if RouteStopPattern exists
      test_rsp = RouteStopPattern.create_from_gtfs(trip, tl_route.onestop_id, stop_pattern, trip_stop_points, feed_shape_points)
      rsp = find_by_entity(test_rsp)
      log "   #{rsp.onestop_id}"  if test_rsp.equal?(rsp)
      add_identifier(rsp, 'trip', trip)
      rsp.trips << trip.trip_id unless rsp.trips.include?(trip.trip_id)
      rsp.route = tl_route
      rsps << rsp
    end
    log "#{stop_times_with_shape_dist_traveled} stop times with shape_dist_traveled found out of #{stop_times_count} total stop times" if stop_times_with_shape_dist_traveled > 0
    rsps
  end

  def find_by_gtfs_entity(entity)
    find_by_onestop_id(@gtfs_to_onestop_id[entity])
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
    @gtfs.trips.each    { |e| rsp_map[e.id]    = @gtfs_to_onestop_id[e]}
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

  ##### Create change payloads ######

  def create_change_payloads(changeset, entity_type, entities, action: 'createUpdate')
    entities.each_slice(CHANGE_PAYLOAD_MAX_ENTITIES).each do |chunk|
      changes = chunk.map do |entity|
        entity.compact! # remove any nil values
        change = {}
        change['action'] = action
        change[entity_type] = entity
        change
      end
      begin
        ChangePayload.create!(
          changeset: changeset,
          payload: {
            changes: changes
          }
        )
      rescue Exception => e
        log "Error: #{e.message}"
        log "Payload:"
        log changes.to_json
        raise e
      end
    end
  end

  def make_change_operator(entity)
    {
      onestopId: entity.onestop_id,
      name: entity.name,
      identifiedBy: entity.identified_by.uniq,
      geometry: entity.geometry,
      tags: entity.tags || {},
      timezone: entity.timezone,
      website: entity.website
    }
  end

  def make_change_stop(entity)
    {
      onestopId: entity.onestop_id,
      name: entity.name,
      identifiedBy: entity.identified_by.uniq,
      geometry: entity.geometry,
      tags: entity.tags || {},
      timezone: entity.timezone
    }
  end

  def make_change_route(entity)
    {
      onestopId: entity.onestop_id,
      name: entity.name,
      color: entity.color,
      identifiedBy: entity.identified_by.uniq,
      operatedBy: entity.operator.onestop_id,
      vehicleType: entity.vehicle_type,
      serves: entity.serves.map(&:onestop_id),
      tags: entity.tags || {},
      geometry: entity.geometry
    }
  end

  def make_change_rsp(entity)
    {
      onestopId: entity.onestop_id,
      identifiedBy: entity.identified_by.uniq,
      stopPattern: entity.stop_pattern,
      geometry: entity.geometry,
      isGenerated: entity.is_generated,
      isModified: entity.is_modified,
      trips: entity.trips,
      traversedBy: entity.route.onestop_id,
      tags: entity.tags || {}
    }
  end

  def make_ssp(route, trip, origin, origin_dist_traveled, destination, destination_dist_traveled, route_stop_pattern)
    # Generate an edge between an origin and destination for a given route/trip
    route = find_by_gtfs_entity(route)
    origin_stop = find_by_gtfs_entity(@gtfs.stop(origin.stop_id))
    destination_stop = find_by_gtfs_entity(@gtfs.stop(destination.stop_id))
    service_period = @gtfs.service_period(trip.service_id)
    ssp = ScheduleStopPair.new(
      # Feed
      feed: @feed,
      feed_version: @feed_version,
      # Origin
      origin: origin_stop,
      origin_timezone: origin_stop.timezone,
      origin_arrival_time: origin.arrival_time.presence,
      origin_departure_time: origin.departure_time.presence,
      origin_dist_traveled: origin_dist_traveled,
      # Destination
      destination: destination_stop,
      destination_timezone: destination_stop.timezone,
      destination_arrival_time: destination.arrival_time.presence,
      destination_departure_time: destination.departure_time.presence,
      destination_dist_traveled: destination_dist_traveled,
      # Route
      route: route,
      route_stop_pattern: route_stop_pattern,
      # Operator
      operator: route.operator,
      # Trip
      trip: trip.id.presence,
      trip_headsign: (origin.stop_headsign || trip.trip_headsign).presence,
      trip_short_name: trip.trip_short_name.presence,
      shape_dist_traveled: destination.shape_dist_traveled.to_f,
      # Accessibility
      pickup_type: to_pickup_type(origin.pickup_type),
      drop_off_type: to_pickup_type(destination.drop_off_type),
      wheelchair_accessible: to_tfn(trip.wheelchair_accessible),
      bikes_allowed: to_tfn(trip.bikes_allowed),
      # service period
      service_start_date: service_period.start_date,
      service_end_date: service_period.end_date,
      service_days_of_week: service_period.iso_service_weekdays,
      service_added_dates: service_period.added_dates,
      service_except_dates: service_period.except_dates
    )
    ssp
  end

  def to_tfn(value)
    case value.to_i
    when 0
      nil
    when 1
      true
    when 2
      false
    end
  end

  def to_pickup_type(value)
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
end

if __FILE__ == $0
  feed_onestop_id = ARGV[0] || 'f-9q9-caltrain'
  path = ARGV[1] || File.open(Rails.root.join('spec/support/example_gtfs_archives/f-9q9-caltrain.zip'))
  import_level = (ARGV[2].presence || 1).to_i
  ####
  feed = Feed.find_by_onestop_id!(feed_onestop_id)
  feed_version = feed.feed_versions.create!
  ####
  t0 = Time.now
  graph = GTFSGraph.new(path, feed, feed_version)
  graph.create_change_osr
  t1 = Time.now
  if import_level >= 2
    graph.ssp_schedule_async do |trip_ids, agency_map, route_map, stop_map, rsp_map|
      graph.ssp_perform_async(trip_ids, agency_map, route_map, stop_map, rsp_map)
    end
  end
  t2 = Time.now
  puts "SSP Time: #{t2-t1}"
  puts "Total Time: #{t2-t0}"
end
