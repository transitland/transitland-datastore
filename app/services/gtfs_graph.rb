class GTFSGraph

  CHANGE_PAYLOAD_MAX_ENTITIES = 1_000
  STOP_TIMES_MAX_LOAD = 100_000

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

  def create_change_osr(import_level)
    @gtfs.load_graph
    operators = Set.new
    routes = Set.new
    stops = Set.new

    # Operators
    @feed.operators_in_feed.each do |oif|
      operator_gtfs = @gtfs.agency(oif.gtfs_agency_id)
      next unless operator_gtfs
      operator = find_by_onestop_id(oif.operator.onestop_id)
      add_identifier(operator, 'o', operator_gtfs)
      operators << operator
      # Routes
      @gtfs.children(operator_gtfs).each do |route_gtfs|
        # Stops
        route_stops = Set.new
        route_stops_gtfs = @gtfs
          .children(route_gtfs)
          .map { |trip_gtfs| @gtfs.children(trip_gtfs) }
          .reduce(Set.new, :+)
        route_stops_gtfs.each do |stop_gtfs|
          stop = find_by_entity(StopPlatform.from_gtfs(stop_gtfs))
          stop.timezone ||= operator.timezone
          add_identifier(stop, 's', stop_gtfs)
          route_stops << stop
          # Stations
          stop_gtfs_parent = @gtfs.stop(stop_gtfs.parent_station)
          next unless stop_gtfs_parent
          station = find_by_entity(StopStation.from_gtfs(stop_gtfs_parent))
          stop.parent_stop = station
          add_identifier(station, 's', stop_gtfs_parent)
          stops << station
        end
        stops |= route_stops
        route = find_by_entity(Route.from_gtfs(route_gtfs, route_stops))
        route.operator = operator
        route.serves ||= Set.new
        route.serves |= route_stops
        add_identifier(route, 'r', route_gtfs)
        routes << route
      end
    end
    # binding.pry
    # operators.map(&:save!)
    # stops.map(&:save!)
    # routes.map(&:save!)
    log "Changeset create"
    changeset = Changeset.create()
    @feed.set_bounding_box_from_stops(stops)
    @feed.save!
    if import_level >= 0
      create_change_payloads(changeset, operators)
    end
    if import_level >= 1
      create_change_payloads(changeset, stops)
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
        change = {}
        change['action'] = 'createUpdate'
        change[entity.class.name.camelize(:lower)] = entity.as_change
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

  def make_change_ssp(entity)
    {
      importedFromFeed: {
        onestopId: @feed.onestop_id,
        sha1: @feed_version.sha1
      },
      originOnestopId: entity.origin.onestop_id,
      originTimezone: entity.origin_timezone,
      originArrivalTime: entity.origin_arrival_time,
      originDepartureTime: entity.origin_departure_time,
      destinationOnestopId: entity.destination.onestop_id,
      destinationTimezone: entity.destination_timezone,
      destinationArrivalTime: entity.destination_arrival_time,
      destinationDepartureTime: entity.destination_departure_time,
      routeOnestopId: entity.route.onestop_id,
      trip: entity.trip,
      tripHeadsign: entity.trip_headsign,
      tripShortName: entity.trip_short_name,
      wheelchairAccessible: entity.wheelchair_accessible,
      bikesAllowed: entity.bikes_allowed,
      dropOffType: entity.drop_off_type,
      pickupType: entity.pickup_type,
      shapeDistTraveled: entity.shape_dist_traveled,
      serviceStartDate: entity.service_start_date,
      serviceEndDate: entity.service_end_date,
      serviceDaysOfWeek: entity.service_days_of_week,
      serviceAddedDates: entity.service_added_dates,
      serviceExceptDates: entity.service_except_dates,
      windowStart: entity.window_start,
      windowEnd: entity.window_end,
      originTimepointSource: entity.origin_timepoint_source,
      destinationTimepointSource: entity.destination_timepoint_source
    }
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
      origin_timezone: origin_stop.timezone,
      origin_arrival_time: origin.arrival_time.presence,
      origin_departure_time: origin.departure_time.presence,
      # Destination
      destination: destination_stop,
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
  FeedEaterWorker.perform_async(feed_onestop_id, nil, 1)
  FeedEaterWorker.drain
  FeedEaterScheduleWorker.drain
end
