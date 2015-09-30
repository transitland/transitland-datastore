class GTFSGraph

  CHANGE_PAYLOAD_MAX_ENTITIES = 1_000
  STOP_TIMES_MAX_LOAD = 100_000

  def initialize(filename, feed=nil)
    # GTFS Graph / TransitLand wrapper
    @feed = feed
    @gtfs = GTFS::Source.build(filename, {strict: false})
    @log = []
    # TL Entity relationships: Many to many
    @tl_served_by = Hash.new { |h,k| h[k] = Set.new }
    @tl_serves = Hash.new { |h,k| h[k] = Set.new }
    # TL <-> GTFS mapping; One to many
    @tl_gtfs = Hash.new { |h,k| h[k] = Set.new }
    @gtfs_tl = {}
    # TL Indexed by Onestop ID
    @tl_by_onestop_id = {}
  end

  def load_tl
    # Clear
    @tl_by_onestop_id.clear
    @tl_gtfs.clear
    @tl_served_by.clear
    @tl_serves.clear
    @gtfs_tl.clear
    # Load GTFS
    log "Load GTFS"
    @gtfs.load_graph
    # Load TL
    log "Load TL"
    self.load_tl_stops
    self.load_tl_routes
    self.load_tl_operators
  end

  def load_tl_stops
    # Build TL Entities
    log "  merge stations"
    # Merge child stations into parents.
    stations = Hash.new { |h,k| h[k] = [] }
    @gtfs.stops.each do |e|
      stations[@gtfs.stop(e.parent_station) || e] << e
    end
    # Merge station/platforms with Datastore Stops.
    log "  stops"
    stations.each do |station,platforms|
      # Temp stop to get geometry and name.
      stop = Stop.from_gtfs(station)
      # Search by similarity
      stop, score = Stop.find_by_similarity(stop[:geometry], stop.name, radius=1000, threshold=0.6)
      # ... or create stop from GTFS
      stop ||= Stop.from_gtfs(station)
      # ... check if Stop exists, or another local Stop, or new.
      stop = Stop.find_by(onestop_id: stop.onestop_id) || @tl_by_onestop_id[stop.onestop_id] || stop
      # TODO: Stop Timezone
      # stop.timezone =
      # Add identifiers and references
      tl_add_identifiers(stop, [station]+platforms)
      # Cache stop
      @tl_by_onestop_id[stop.onestop_id] = stop
      if score
        log "    #{stop.onestop_id}: #{stop.name} (search: #{station.name} = #{'%0.2f'%score.to_f})"
      else
        log "    #{stop.onestop_id}: #{stop.name}"
      end
    end
  end

  def load_tl_routes
    # Routes
    log "  routes"
    @gtfs.routes.each do |e|
      # Find: (child gtfs trips) to (child gtfs stops) to (tl stops)
      stops = @gtfs.children(e)
        .map { |i| @gtfs.children(i) }
        .reduce(Set.new, :+)
        .map { |i| @gtfs_tl[i] }
        .to_set
      # Skip Route if no Stops
      next if stops.empty?
      # Find uniq shape_ids of trip_ids, filter missing shapes, build geometry.
      geometry = Route::GEOFACTORY.multi_line_string(
        @gtfs
          .children(e)
          .map(&:shape_id)
          .uniq
          .compact
          .map { |shape_id| @gtfs.shape_line(shape_id) }
          .map { |coords| Route::GEOFACTORY.line_string( coords.map { |lon, lat| Route::GEOFACTORY.point(lon, lat) } ) }
      )
      # Search by similarity
      # ... or create route from GTFS
      route = Route.from_gtfs(e, stops)
      # ... check if Route exists, or another local Route, or new.
      route = Route.find_by(onestop_id: route.onestop_id) || @tl_by_onestop_id[route.onestop_id] || route
      # Set geometry
      route[:geometry] = geometry
      # Add identifiers and references
      tl_add_identifiers(route, e)
      tl_add_serves(route, stops)
      # Cache route
      @tl_by_onestop_id[route.onestop_id] = route
      log "    #{route.onestop_id}: #{route.name}"
    end
  end

  def load_tl_operators
    # Operators
    log "  operators"
    operators = Set.new
    @feed.operators_in_feed.each do |oif|
      e = @gtfs.agency(oif.gtfs_agency_id)
      # Skip Operator if not found
      next unless e
      # Find: (child gtfs routes) to (tl routes)
      #   note: .compact because some gtfs routes are skipped.
      routes = @gtfs.children(e)
        .map { |i| @gtfs_tl[i] }
        .compact
        .to_set
      # Find: (tl routes) to (serves tl stops)
      stops = routes
        .map { |r| @tl_serves[r] }
        .reduce(Set.new, :+)
      # Create Operator from GTFS
      operator = Operator.from_gtfs(e, stops)
      operator.onestop_id = oif.operator.onestop_id # Override Onestop ID
      operator_original = operator # for merging geometry
      # ... or check if Operator exists, or another local Operator, or new.
      operator = Operator.find_by(onestop_id: operator.onestop_id) || @tl_by_onestop_id[operator.onestop_id] || operator
      # Merge convex hulls
      operator[:geometry] = Operator.convex_hull([operator, operator_original], as: :wkt, projected: false)
      # Copy Operator timezone to fill missing Stop timezones
      stops.each { |stop| stop.timezone ||= operator.timezone }
      # Add identifiers
      tl_add_identifiers(operator, e)
      tl_add_serves(operator, routes)
      # Cache Operator
      @tl_by_onestop_id[operator.onestop_id] = operator
      # Add to found operators
      operators << operator
      log "    #{operator.onestop_id}: #{operator.name}"
    end
    # Return operators
    operators
  end

  def create_changeset(operators, import_level=0)
    raise ArgumentError.new('At least one operator required') if operators.empty?
    raise ArgumentError.new('import_level must be 0, 1, or 2.') unless (0..2).include?(import_level)
    log "Create Changeset"
    operators = operators
    routes = operators.map { |i| @tl_serves[i] }.reduce(Set.new, :+)
    stops = routes.map { |i| @tl_serves[i] }.reduce(Set.new, :+)
    action = 'createUpdate'
    changeset = Changeset.create()

    # Operators
    if import_level >= 0
      counter = 0
      operators.each_slice(CHANGE_PAYLOAD_MAX_ENTITIES).each do |chunk|
        log "  operators: #{counter} - #{counter+chunk.size} of #{operators.size}"
        counter += chunk.size
        ChangePayload.create!(
          changeset: changeset,
          payload: {
            changes: chunk.map { |entity|
              {
                action: action,
                operator: make_change_operator(entity)
              }
            }
          }
        )
      end
    end

    # Stops
    if import_level >= 1
      counter = 0
      stops.each_slice(CHANGE_PAYLOAD_MAX_ENTITIES).each do |chunk|
        log "  stops: #{counter} - #{counter+chunk.size} of #{stops.size}"
        counter += chunk.size
        ChangePayload.create!(
          changeset: changeset,
          payload: {
            changes: chunk.map { |entity|
              {
                action: action,
                stop: make_change_stop(entity)
              }
            }
          }
        )
      end

      # Routes
      counter = 0
      routes.each_slice(CHANGE_PAYLOAD_MAX_ENTITIES).each do |chunk|
        log "  routes: #{counter} - #{counter+chunk.size} of #{routes.size}"
        counter += chunk.size
        ChangePayload.create!(
          changeset: changeset,
          payload: {
            changes: chunk.map { |entity|
              {
                action: action,
                route: make_change_route(entity)
              }
            }
          }
        )
      end
    end

    if import_level >= 2
      trip_counter = 0
      ssp_counter = 0
      @gtfs.trip_chunks(STOP_TIMES_MAX_LOAD) do |trip_chunk|
        log "  trips: #{trip_counter} - #{trip_counter+trip_chunk.size}"
        trip_counter += trip_chunk.size
        ssp_chunk = []
        @gtfs.trip_stop_times(trip_chunk) do |trip,stop_times|
          log "    trip id: #{trip.trip_id}, stop_times: #{stop_times.size}"
          route = @gtfs.route(trip.route_id)
          # Create SSPs for all stop_time edges
          ssp_trip = []
          stop_times[0..-2].zip(stop_times[1..-1]).each do |origin,destination|
            ssp_trip << make_ssp(route,trip,origin,destination)
          end
          # Interpolate stop_times
          ScheduleStopPair.interpolate(ssp_trip)
          # Add to chunk
          ssp_chunk += ssp_trip
        end
        # Create changeset
        ssp_chunk.each_slice(CHANGE_PAYLOAD_MAX_ENTITIES) do |chunk|
          log "    ssp changes: #{ssp_counter} - #{ssp_counter+chunk.size}"
          ssp_counter += chunk.size
          ChangePayload.create!(
            changeset: changeset,
            payload: {
              changes: chunk.map { |entity|
                {
                  action: action,
                  scheduleStopPair: make_change_ssp(entity)
                }
              }
            }
          )
        end
      end
    end

    # Apply changeset
    log "  changeset apply"
    changeset.apply!
    log "  changeset apply done"
  end

  def import_log
    @log.join("\n")
  end

  ##### GTFS by ID #####

  private

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

  ##### Relationships between entities #####

  def tl_add_identifiers(tl, gtfs_entities)
    # Associate TL entity with one or more GTFS entities.
    Array(gtfs_entities).each do |entity|
      @tl_gtfs[tl].add(entity)
      @gtfs_tl[entity] = tl
    end
  end

  def tl_add_serves(tl, tl_entities)
    # Associate TL entity with serving relationships.
    Array(tl_entities).each do |entity|
      @tl_serves[tl].add(entity)
      @tl_served_by[entity].add(tl)
    end
  end

  ##### Create change payloads ######

  def make_change_operator(entity)
    {
      onestopId: entity.onestop_id,
      name: entity.name,
      identifiedBy: @tl_gtfs[entity].map { |i| OnestopId::create_identifier(@feed.onestop_id, 'o', i.id)},
      importedFromFeedOnestopId: @feed.onestop_id,
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
      identifiedBy: @tl_gtfs[entity].map { |i| OnestopId::create_identifier(@feed.onestop_id, 's', i.id)},
      importedFromFeedOnestopId: @feed.onestop_id,
      geometry: entity.geometry,
      tags: entity.tags || {},
      timezone: entity.timezone
    }
  end

  def make_change_route(entity)
    {
      onestopId: entity.onestop_id,
      name: entity.name,
      identifiedBy: @tl_gtfs[entity].map { |i| OnestopId::create_identifier(@feed.onestop_id, 'r', i.id)},
      importedFromFeedOnestopId: @feed.onestop_id,
      operatedBy: @tl_served_by[entity].map(&:onestop_id).first,
      serves: @tl_serves[entity].map(&:onestop_id),
      tags: entity.tags || {},
      geometry: entity.geometry
    }
  end

  def make_change_ssp(entity)
    {
      imported_from_feed_onestop_id: @feed.onestop_id,
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
    route = @gtfs_tl[route]
    origin_stop = @gtfs_tl[@gtfs.stop(origin.stop_id)]
    destination_stop = @gtfs_tl[@gtfs.stop(destination.stop_id)]
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
      wheelchair_accessible: trip.wheelchair_accessible.to_i,
      bikes_allowed: trip.bikes_allowed.to_i,
      # Stop Time
      drop_off_type: origin.drop_off_type.to_i,
      pickup_type: origin.pickup_type.to_i,
      shape_dist_traveled: origin.shape_dist_traveled.to_f,
      # service period
      service_start_date: service_period.start_date,
      service_end_date: service_period.end_date,
      service_days_of_week: service_period.iso_service_weekdays,
      service_added_dates: service_period.added_dates,
      service_except_dates: service_period.except_dates
    )
  end
end

if __FILE__ == $0
  # ActiveRecord::Base.logger = Logger.new(STDOUT)
  feedid = ARGV[0] || 'f-9q9-caltrain'
  filename = "tmp/transitland-feed-data/#{feedid}.zip"
  import_level = (ARGV[1] || 1).to_i
  feed = Feed.find_by!(onestop_id: feedid)
  graph = GTFSGraph.new(filename, feed)
  operators = graph.load_tl
  graph.create_changeset(operators, import_level=import_level)
end
