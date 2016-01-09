class GTFSGraph
  CHANGE_PAYLOAD_MAX_ENTITIES = Figaro.env.feed_eater_change_payload_max_entities.try(:to_i) || 1_000
  STOP_TIMES_MAX_LOAD = Figaro.env.feed_eater_stop_times_max_load.try(:to_i) || 100_000

  def initialize(filename, feed, feed_version)
    # GTFS Graph / TransitLand wrapper
    @feed = feed
    @feed_version = feed_version
    @gtfs = GTFS::Source.build(filename, {strict: false})
    @log = []
    # GTFS entity to Onestop ID
    @gtfs_to_onestop_id = {}
    # TL Indexed by Onestop ID
    @onestop_id_to_entity = {}
  end

  def create_change_osr(import_level=0)
    raise ArgumentError.new('import_level must be 0, 1, or 2.') unless (0..2).include?(import_level)
    log "Load GTFS"
    @gtfs.load_graph
    log "Load TL"
    load_tl_stops
    load_tl_routes
    operators = load_tl_operators
    routes = operators.
             map(&:serves).
             reduce(Set.new, :+).
             map { |i| find_by_onestop_id(i) }
    stops = routes.
            map(&:serves).
            reduce(Set.new, :+).
            map { |i| find_by_onestop_id(i) }
    operators.each { |o| o.serves = nil }
    log "Create changeset"
    changeset = Changeset.create()
    log "Create: Operators, Stops, Routes"
    # Update Feed Bounding Box
    log "  updating feed bounding box"
    @feed.set_bounding_box_from_stops(stops)
    # FIXME: Run through changeset
    @feed.save!
    if import_level >= 0
      log "  operators: #{operators.size}"
      create_change_payloads(changeset, operators)
    end
    if import_level >= 1
      log "  stops: #{stops.size}"
      create_change_payloads(changeset, stops)
      log "  routes: #{routes.size}"
      create_change_payloads(changeset, routes)
    end
    log "Changeset apply"
    t = Time.now
    changeset.apply!
    log "  apply done: time #{Time.now - t}"
  end

  def ssp_schedule_async
    agency_map, route_map, stop_map = make_gtfs_id_map
    @gtfs.trip_chunks(STOP_TIMES_MAX_LOAD) do |trips|
      trip_ids = trips.map(&:id)
      yield trip_ids, agency_map, route_map, stop_map
    end
  end

  def ssp_perform_async(trip_ids, agency_map, route_map, stop_map)
    log "Load GTFS"
    @gtfs.agencies
    @gtfs.routes
    @gtfs.stops
    @gtfs.trips
    load_gtfs_id_map(agency_map, route_map, stop_map)
    trips = trip_ids.map { |trip_id| @gtfs.trip(trip_id) }
    log "Create changeset"
    changeset = Changeset.create()
    log "Create: SSPs"
    total = 0
    ssps = []
    @gtfs.trip_stop_times(trips) do |trip,stop_times|
      # log "    trip id: #{trip.trip_id}, stop_times: #{stop_times.size}"
      route = @gtfs.route(trip.route_id)
      # Create SSPs for all stop_time edges
      ssp_trip = []
      stop_times[0..-2].zip(stop_times[1..-1]).each do |origin,destination|
        ssp_trip << make_ssp(route, trip, origin, destination)
      end
      # Interpolate stop_times
      ScheduleStopPair.interpolate(ssp_trip)
      # Add to chunk
      ssps += ssp_trip
      # If chunk is big enough, create change payloads.
      if ssps.size >= CHANGE_PAYLOAD_MAX_ENTITIES
        log  "  ssps: #{total} - #{total+ssps.size}"
        total += ssps.size
        create_change_payloads(changeset, ssps)
        ssps = []
      end
    end
    # Create any trailing payloads
    if ssps.size > 0
      log  "  ssps: #{total} - #{total+ssps.size}"
      total += ssps.size
      create_change_payloads(changeset, ssps)
    end
    log "Changeset apply"
    t = Time.now
    changeset.apply!
    log "  apply done: total time: #{Time.now - t}"
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
    # Merge child stations into parents.
    log "  merge stations"
    stations = Hash.new { |h,k| h[k] = [] }
    @gtfs.stops.each do |stop|
      stations[@gtfs.stop(stop.parent_station) || stop] << stop
    end
    # Merge station/platforms with Stops.
    log "  stops"
    stations.each do |station,platforms|
      # Temp stop to get geometry and name.
      stop = Stop.from_gtfs(station)
      # Search by similarity
      stop, score = Stop.find_by_similarity(stop[:geometry], stop.name, radius=1000, threshold=0.6)
      # ... or create stop from GTFS
      stop ||= Stop.from_gtfs(station)
      # ... check if Stop exists, or another local Stop, or new.
      stop = find_by_entity(stop)
      # Add identifiers and references
      ([station]+platforms).each { |e| add_identifier(stop, 's', e) }
      # Cache stop
      if score
        log "    #{stop.onestop_id}: #{stop.name} (search: #{station.stop_name} = #{'%0.2f'%score.to_f})"
      else
        log "    #{stop.onestop_id}: #{stop.name}"
      end
    end
  end

  def load_tl_routes
    # Routes
    log "  routes"
    @gtfs.routes.each do |entity|
      # Find: (child gtfs trips) to (child gtfs stops) to (tl stops)
      stops = @gtfs.children(entity)
        .map { |trip| @gtfs.children(trip) }
        .reduce(Set.new, :+)
        .map { |stop| find_by_gtfs_entity(stop) }
        .to_set
      # Skip Route if no Stops
      next if stops.empty?
      # Find uniq shape_ids of trip_ids, filter missing shapes, build geometry.
      geometry = Route::GEOFACTORY.multi_line_string(
        @gtfs
          .children(entity)
          .map(&:shape_id)
          .uniq
          .compact
          .map { |shape_id| @gtfs.shape_line(shape_id) }
          .map { |coords| Route::GEOFACTORY.line_string( coords.map { |lon, lat| Route::GEOFACTORY.point(lon, lat) } ) }
      )
      # Search by similarity
      # ... or create route from GTFS
      route = Route.from_gtfs(entity, stops)
      # ... check if Route exists, or another local Route, or new.
      route = find_by_entity(route)
      # Set geometry
      route[:geometry] = geometry
      # Add references and identifiers
      route.serves ||= Set.new
      route.serves |= stops.map(&:onestop_id)
      add_identifier(route, 'r', entity)
      log "    #{route.onestop_id}: #{route.name}"
    end
  end

  def load_tl_operators
    # Operators
    log "  operators"
    operators = Set.new
    @feed.operators_in_feed.each do |oif|
      entity = @gtfs.agency(oif.gtfs_agency_id)
      # Skip Operator if not found
      next unless entity
      # Find: (child gtfs routes) to (tl routes)
      #   note: .compact because some gtfs routes are skipped.
      routes = @gtfs.children(entity)
        .map { |route| find_by_gtfs_entity(route) }
        .compact
        .to_set
      # Find: (tl routes) to (serves tl stops)
      stops = routes
        .map { |route| route.serves }
        .reduce(Set.new, :+)
        .map { |i| find_by_onestop_id(i) }
      # Create Operator from GTFS
      operator = Operator.from_gtfs(entity, stops)
      operator.onestop_id = oif.operator.onestop_id # Override Onestop ID
      operator_original = operator # for merging geometry
      # ... or check if Operator exists, or another local Operator, or new.
      operator = find_by_entity(operator)
      # Merge convex hulls
      operator[:geometry] = Operator.convex_hull([operator, operator_original], as: :wkt, projected: false)
      # Copy Operator timezone to fill missing Stop timezones
      stops.each { |stop| stop.timezone ||= operator.timezone }
      # Add references and identifiers
      routes.each { |route| route.operated_by = operator.onestop_id }
      operator.serves ||= Set.new
      operator.serves |= routes.map(&:onestop_id)
      add_identifier(operator, 'o', entity)
      # Cache Operator
      # Add to found operators
      operators << operator
      log "    #{operator.onestop_id}: #{operator.name}"
    end
    # Return operators
    operators
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
    @gtfs.agencies.each { |e| agency_map[e.id] = @gtfs_to_onestop_id[e]}
    @gtfs.routes.each   { |e| route_map[e.id]  = @gtfs_to_onestop_id[e]}
    @gtfs.stops.each    { |e| stop_map[e.id]   = @gtfs_to_onestop_id[e]}
    [agency_map, route_map, stop_map]
  end

  def load_gtfs_id_map(agency_map, route_map, stop_map)
    @gtfs_to_onestop_id.clear
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
  end

  ##### Create change payloads ######

  def create_change_payloads(changeset, entities)
    entities.each_slice(CHANGE_PAYLOAD_MAX_ENTITIES).each do |chunk|
      changes = chunk.map do |entity|
        change = entity.as_change.compact
        change[:importedFromFeed] = {
          onestopId: @feed.onestop_id,
          sha1: @feed_version.sha1
        }
        {
          :action => :createUpdate,
          entity.class.name.camelize(:lower) => change
        }
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

  def make_ssp(route, trip, origin, destination)
    # Generate an edge between an origin and destination for a given route/trip
    route = find_by_gtfs_entity(route)
    origin_stop = find_by_gtfs_entity(@gtfs.stop(origin.stop_id))
    destination_stop = find_by_gtfs_entity(@gtfs.stop(destination.stop_id))
    service_period = @gtfs.service_period(trip.service_id)
    ScheduleStopPair.new(
      # Origin
      origin: origin_stop,
      origin_onestop_id: origin_stop.onestop_id,
      origin_timezone: origin_stop.timezone,
      origin_arrival_time: origin.arrival_time.presence,
      origin_departure_time: origin.departure_time.presence,
      # Destination
      destination: destination_stop,
      destination_onestop_id: destination_stop.onestop_id,
      destination_timezone: destination_stop.timezone,
      destination_arrival_time: destination.arrival_time.presence,
      destination_departure_time: destination.departure_time.presence,
      # Route
      route: route,
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
  require 'sidekiq/testing'
  ActiveRecord::Base.logger = Logger.new(STDOUT)
  feed_onestop_id = ARGV[0] || 'f-9q9-caltrain'
  FeedFetcherWorker.perform_async(feed_onestop_id)
  FeedFetcherWorker.drain
  FeedEaterWorker.perform_async(feed_onestop_id, nil, 2)
  FeedEaterWorker.drain
  FeedEaterScheduleWorker.drain
end
