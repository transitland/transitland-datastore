class GTFSGraph
  
  DAYS_OF_WEEK = [:monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday]
  CHANGE_PAYLOAD_MAX_ENTITIES = 1_000
  STOP_TIMES_MAX_LOAD = 1_000_000
    
  def initialize(filename, feed=nil)
    # GTFS Graph / TransitLand wrapper
    @filename = filename
    @feed = feed
    @gtfs = GTFS::Source.build(filename, {strict: false})

    # TL Entity relationships: Many to many
    @tl_served_by = Hash.new { |h,k| h[k] = Set.new }
    @tl_serves = Hash.new { |h,k| h[k] = Set.new }
    # TL <-> GTFS mapping; One to many
    @tl_gtfs = Hash.new { |h,k| h[k] = Set.new }
    @gtfs_tl = {}
    # TL Indexed by Onestop ID
    @tl_by_onestop_id = {}

    # TODO: Move these to GTFS Library...
    # GTFS entities indexed by type and id
    @gtfs_by_id = Hash.new { |h,k| h[k] = {} }
    # GTFS Entity relationships: Many to many
    @gtfs_parents = Hash.new { |h,k| h[k] = Set.new }
    @gtfs_children = Hash.new { |h,k| h[k] = Set.new }
    # Shapes
    @shape_by_id = {}
    # Service dates
    @service_by_id = {}
    # Trip stop counters; used for batching stop_times
    @trip_counter = Hash.new { |h,k| h[k] = 0 }
  end
  
  def load_gtfs
    # Load core GTFS entities and build relationships
    debug "Load GTFS"
    # Clear
    @gtfs_by_id.clear
    @gtfs_parents.clear
    @gtfs_children.clear
    @trip_counter.clear
    
    # Load GTFS agencies, routes, stops, trips
    # Use .each_entity instead of .entity.each; faster, skip caching.
    debug "  core"
    @gtfs.each_agency { |e| @gtfs_by_id[:agencies][e.id] = e }
    @gtfs.each_route { |e| @gtfs_by_id[:routes][e.id] = e }
    @gtfs.each_stop { |e| @gtfs_by_id[:stops][e.id] = e }
    @gtfs.each_trip { |e| @gtfs_by_id[:trips][e.id] = e }

    # Load service periods
    debug "  calendars"
    @gtfs.each_calendar { |e| make_service(e) } rescue debug "  warning: no calendar.txt"
    @gtfs.each_calendar_date { |e| make_service(e) } rescue debug "  warning: no calendar_dates.txt"

    # Load shapes.
    debug "  shapes"
    shapes_merge = Hash.new { |h,k| h[k] = [] }
    @gtfs.each_shape { |e| shapes_merge[e.id] << e }
    shapes_merge.each { |k,v| 
      @shape_by_id[k] = Route::GEOFACTORY.line_string(
        v
          .sort_by { |i| i.pt_sequence.to_i }
          .map { |i| Route::GEOFACTORY.point(i.pt_lon, i.pt_lat) }
      )
    }
    
    # Create relationships
    debug "  relationships"
    # Set default agency    
    default_agency = @gtfs_by_id[:agencies].first[1].id    
    # Add routes to agencies
    @gtfs_by_id[:routes].each do |k,e| 
      agency = @gtfs_by_id[:agencies][e.agency_id || default_agency]
      gtfs_pclink(agency, e)
    end

    # Add trips to routes
    @gtfs_by_id[:trips].each do |k,e| 
      route = @gtfs_by_id[:routes][e.route_id]
      gtfs_pclink(route, e)
    end

    # Associate routes with stops; count stop_times by trip
    debug "  stop_times counter"
    @gtfs.each_stop_time do |e| 
      trip = @gtfs_by_id[:trips][e.trip_id]
      stop = @gtfs_by_id[:stops][e.stop_id]
      @trip_counter[trip] += 1
      gtfs_pclink(trip, stop)
    end
  end

  def load_tl
    debug "Load TL"
    # Clear
    @tl_by_onestop_id.clear
    @tl_gtfs.clear
    @tl_served_by.clear
    @tl_serves.clear
    @gtfs_tl.clear
    
    # Build TL Entities
    debug "  merge stations"
    # Merge child stations into parents.
    stations = Hash.new { |h,k| h[k] = [] }
    @gtfs_by_id[:stops].each do |k,e|
      stations[@gtfs_by_id[:stops][e.parent_station] || e] << e
    end
    
    # Merge station/platforms with Datastore Stops.
    debug "  stops"
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
        debug "    #{stop.onestop_id}: #{stop.name} (search: #{station.name} = #{'%0.2f'%score.to_f})"
      else
        debug "    #{stop.onestop_id}: #{stop.name}"
      end
    end
    
    # Routes
    debug "  routes"
    @gtfs_by_id[:routes].each do |k,e|
      # Find: (child gtfs trips) to (child gtfs stops) to (tl stops)
      stops = @gtfs_children[e]
        .map { |i| @gtfs_children[i] }
        .reduce(Set.new, :+)
        .map { |i| @gtfs_tl[i] }
        .to_set
      # Skip Route if no Stops
      next if stops.empty?
      # Find all unique shapes, and build geometry.
      geometry = Route::GEOFACTORY.multi_line_string(
        @gtfs_children[e]
          .map { |i| i.shape_id }
          .uniq
          .map { |i| @shape_by_id[i] }
      )
      # Search by similarity
      # TODO: route similarity... 
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
      debug "    #{route.onestop_id}: #{route.name}"
    end

    # Operators
    debug "  operators"
    operators = Set.new
    @feed.operators_in_feed.each do |oif| 
      e = @gtfs_by_id[:agencies][oif['gtfs_agency_id']]
      # Skip Operator if not found
      next unless e
      # Find: (child gtfs routes) to (tl routes)
      #   note: .compact because some gtfs routes are skipped.
      routes = @gtfs_children[e]
        .map { |i| @gtfs_tl[i] }
        .compact
        .to_set
      # Find: (tl routes) to (serves tl stops)
      stops = routes
        .map { |r| @tl_serves[r] }
        .reduce(Set.new, :+)
      # Create Operator from GTFS
      operator = Operator.from_gtfs(e, stops)
      operator.onestop_id = oif['onestop_id'] # Override Onestop ID
      operator_original = operator # for merging geometry
      # ... or check if Operator exists, or another local Operator, or new.
      operator = Operator.find_by(onestop_id: operator.onestop_id) || @tl_by_onestop_id[operator.onestop_id] || operator    
      # Merge convex hulls
      operator[:geometry] = Operator.convex_hull([operator, operator_original], as: :wkt, projected: false)
      # Add identifiers
      tl_add_identifiers(operator, e)
      tl_add_serves(operator, routes)
      # Cache Operator
      @tl_by_onestop_id[operator.onestop_id] = operator
      # Add to found operators
      operators << operator
      debug "    #{operator.onestop_id}: #{operator.name}"
    end
    # Return operators
    operators
  end
  
  def create_changeset(operators, import_level=0)
    raise ArgumentError.new('At least one operator required') if operators.empty?
    raise ArgumentError.new('import_level must be 0, 1, or 2.') unless (0..2).include?(import_level)
    debug "Create Changeset"
    operators = operators
    routes = operators.map { |i| @tl_serves[i] }.reduce(Set.new, :+)
    stops = routes.map { |i| @tl_serves[i] }.reduce(Set.new, :+)
    action = 'createUpdate'
    changeset = Changeset.create()
    
    # Operators
    if import_level >= 0
      operators.each_slice(CHANGE_PAYLOAD_MAX_ENTITIES).each do |chunk|
        debug "  operators: #{chunk.size}"
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
      stops.each_slice(CHANGE_PAYLOAD_MAX_ENTITIES).each do |chunk|
        debug "  stops: #{chunk.size}"
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
      routes.each_slice(CHANGE_PAYLOAD_MAX_ENTITIES).each do |chunk|
        debug "  routes: #{chunk.size}"
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
      counter = 0
      trip_chunks(STOP_TIMES_MAX_LOAD) do |trip_chunk|
        counter += trip_chunk.size
        stop_pairs(trip_chunk).each_slice(CHANGE_PAYLOAD_MAX_ENTITIES) do |chunk|
          debug "  trips #{counter} / #{@trip_counter.size}: #{chunk.size} stop pairs"
          ChangePayload.create!(
            changeset: changeset,
            payload: {
              changes: chunk.map { |entity|
                {
                  action: action,
                  scheduleStopPair: entity
                }
              }
            }
          )
        end
      end
    end

    # Apply changeset
    debug "  changeset apply"
    changeset.apply!    
    debug "  changeset apply done"
  end  
  
  ##### GTFS by ID #####
  
  private
  
  def debug(msg)
    # Debug logging
    if Sidekiq::Logging.logger
      Sidekiq::Logging.logger.info msg
    elsif Rails.logger
      Rails.logger.info msg
    else
      puts msg
    end
  end
  
  ##### Relationships between entities #####
  
  def gtfs_pclink(parent, child)
    @gtfs_children[parent].add(child)
    @gtfs_parents[child].add(parent)
  end
  
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
  
  ##### Trip pairs and stop chunks #####
  
  def trip_chunks(batchsize)
    # Return chunks of trips containing approx. batchsize stop_times.
    # Reverse sort trips
    trips = @trip_counter.sort_by { |k,v| -v }
    chunk = []
    current = 0
    trips.each do |k,v|
      if current+v > batchsize
        yield chunk
        chunk = []
        current = 0
      end
      chunk << k
      current += v
    end
    yield chunk
  end
  
  def stop_pairs(trips)
    # Return all the ScheduleStopPairs for a set of trips
    # TODO: Lazy enumerator
    ret = []
    # Trip IDs
    trip_ids = Set.new trips.map(&:id)

    # Sub graph mapping trip IDs to stop_times
    trip_ids_stop_times = Hash.new {|h,k| h[k] = []}
    @gtfs.each_stop_time do |stop_time|
      next unless trip_ids.include?(stop_time.trip_id)
      trip_ids_stop_times[stop_time.trip_id] << stop_time
    end 
    
    # Process each trip
    trip_ids_stop_times.each do |trip_id, stop_times|
      # Get trip and route entities
      trip = @gtfs_by_id[:trips][trip_id]
      # Sort stop_times by stop_sequence
      stop_times = stop_times.sort_by { |x| x.stop_sequence.to_i }
      # Zip edges
      stop_times[0..-2].zip(stop_times[1..-1]).each do |origin,destination|
        # Yield edge
        ret << make_ssp(trip, origin, destination)
      end
    end
    ret
  end
  
  ##### Create change payloads ######
  
  def make_change_operator(entity)
    {
      onestopId: entity.onestop_id,
      name: entity.name,
      identifiedBy: @tl_gtfs[entity].map { |i| "gtfs://#{@feed.onestop_id}/o/#{i.id}"},
      importedFromFeedOnestopId: @feed.onestop_id,
      geometry: entity.geometry,
      tags: entity.tags || {}
    }
  end
  
  def make_change_stop(entity)
    {
      onestopId: entity.onestop_id,
      name: entity.name,
      identifiedBy: @tl_gtfs[entity].map { |i| "gtfs://#{@feed.onestop_id}/s/#{i.id}"},
      importedFromFeedOnestopId: @feed.onestop_id,
      geometry: entity.geometry,
      tags: entity.tags || {}
    }
  end
  
  def make_change_route(entity)
    {
      onestopId: entity.onestop_id,
      name: entity.name,
      identifiedBy: @tl_gtfs[entity].map { |i| "gtfs://#{@feed.onestop_id}/r/#{i.id}" },
      importedFromFeedOnestopId: @feed.onestop_id,
      operatedBy: @tl_served_by[entity].map(&:onestop_id).first,
      serves: @tl_serves[entity].map(&:onestop_id),
      tags: entity.tags || {},
      geometry: entity.geometry,
    }
  end
  
  def make_ssp(trip, origin, destination)
    # Generate an edge between an origin and destination for a given route/trip
    route = @gtfs_tl[@gtfs_by_id[:routes][trip.route_id]]
    origin_stop = @gtfs_tl[@gtfs_by_id[:stops][origin.stop_id]]
    destination_stop = @gtfs_tl[@gtfs_by_id[:stops][destination.stop_id]]
    ssp = {
      # Origin
      originOnestopId: origin_stop.onestop_id,
      originTimezone: origin_stop.timezone,
      originArrivalTime: origin.arrival_time,
      originDepartureTime: origin.departure_time,
      # Destination
      destinationOnestopId: destination_stop.onestop_id,
      destinationTimezone: destination_stop.timezone,
      destinationArrivalTime: destination.arrival_time,
      destinationDepartureTime: destination.departure_time,
      # Route
      routeOnestopId: route.onestop_id,
      # Trip
      trip: trip.id,
      tripHeadsign: (origin.stop_headsign || trip.headsign),
      tripShortName: trip.short_name,
      wheelchairAccessible: trip.wheelchair_accessible.to_i,
      # bikes_allowed: trip.bikes_allowed.to_i,
      # Stop Time
      dropOffType: origin.drop_off_type.to_i,
      pickupType: origin.pickup_type.to_i,
      # timepoint: origin.timepoint.to_i,
      shapeDistTraveled: origin.shape_dist_traveled.to_f,
      importedFromFeedOnestopId: @feed.onestop_id,      
    }
    # Raise Exception if service_id not found.
    ssp.update(@service_by_id.fetch(trip.service_id))
    ssp
  end

  def make_service(entity)
    # Turn calendar.txt & calendar_dates.txt into hashes; copied into SSPs
    # Note: String.to_date is Rails, not plain Ruby.
    service = @service_by_id[entity.service_id]
    # Default service
    service ||= {
      serviceStartDate: nil,
      serviceEndDate: nil,
      serviceDaysOfWeek: [false] * 7,
      serviceAddedDates: [],
      serviceExceptDates: []
    }
    # check if we're calendar.txt, ...
    service[:serviceStartDate] ||= entity.try(:start_date).try(:to_date)
    service[:serviceEndDate] ||= entity.try(:end_date).try(:to_date)
    if entity.respond_to?(:monday)
      service[:serviceDaysOfWeek] = DAYS_OF_WEEK.map { |i| !entity.send(i).to_i.zero? }
    end
    # or calendar_dates.txt
    if entity.respond_to?(:date)
      if entity.exception_type.to_i == 1
        service[:serviceAddedDates] << entity.date.to_date
      else
        service[:serviceExceptDates] << entity.date.to_date
      end      
    end
    @service_by_id[entity.service_id] = service
    service
  end
end

if __FILE__ == $0
  feedid = ARGV[0] || 'f-9q9-caltrain'
  filename = "tmp/transitland-feed-data/#{feedid}.zip"
  import_level = (ARGV[1] || 1).to_i
  ######
  Feed.update_feeds_from_feed_registry
  feed = Feed.find_by!(onestop_id: feedid)
  graph = GTFSGraph.new(filename, feed)
  graph.load_gtfs
  operators = graph.load_tl
  graph.create_changeset(operators, import_level=import_level)
end
