require 'gtfs'
require 'Set'

ActiveRecord::Base.logger = Logger.new(STDOUT)

class GTFSGraph
  
  DAYS_OF_WEEK = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
  
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
  
  def load_graph
    # Clear
    @gtfs_by_id.clear
    @gtfs_parents.clear
    @gtfs_children.clear
    @trip_counter.clear
    
    # Load GTFS agencies, routes, stops, trips
    @gtfs.agencies.each { |e| @gtfs_by_id[:agencies][e.id] = e }
    @gtfs.routes.each { |e| @gtfs_by_id[:routes][e.id] = e }
    @gtfs.stops.each { |e| @gtfs_by_id[:stops][e.id] = e }
    @gtfs.trips.each { |e| @gtfs_by_id[:trips][e.id] = e }

    # Load service periods
    @gtfs.calendars.each { |e| make_service(e) }    
    @gtfs.calendar_dates.each { |e| make_service(e) }

    # Load shapes.
    shapes_merge = Hash.new { |h,k| h[k] = [] }
    @gtfs.shapes.each { |e| shapes_merge[e.id] << e }
    shapes_merge.each { |k,v| 
      @shape_by_id[k] = Route::GEOFACTORY.line_string(
        v
          .sort_by { |i| i.pt_sequence.to_i }
          .map { |i| Route::GEOFACTORY.point(i.pt_lon, i.pt_lat) }
      )
    }
    
    # Set default agency
    default_agency = @gtfs_by_id[:agencies].first[1].id    
    # Add routes to agencies
    @gtfs_by_id[:routes].each do |k,e| 
      agency = self.agency(e.agency_id || default_agency)
      gtfs_pclink(agency, e)
    end

    # Add trips to routes
    @gtfs_by_id[:trips].each do |k,e| 
      route = self.route(e.route_id)
      gtfs_pclink(route, e)
    end

    # Associate routes with stops; count stop_times by trip
    @gtfs.stop_times.each do |e| 
      trip = self.trip(e.trip_id)
      stop = self.stop(e.stop_id)      
      @trip_counter[trip] += 1
      gtfs_pclink(trip, stop)
    end
  end

  def load_tl
    # Clear
    @tl_gtfs.clear
    @tl_served_by.clear
    @tl_serves.clear
    @gtfs_tl.clear
    
    # Build TL Entities
    # Merge child stations into parents.
    stations = Hash.new { |h,k| h[k] = [] }
    @gtfs_by_id[:stops].each do |k,e|
      stations[stop(e.parent_station || e.id)] << e
    end
    # puts "Stops: #{@gtfs_by_id[:stops].size} / Merged: #{stations.size}" 
    
    # Merge station/platforms with Datastore Stops.
    stations.each do |station,platforms|
      stop = Stop.from_gtfs(station) # used for find_by
      score, stop = Stop.find_by_similarity(stop[:geometry], stop.name, radius=1000, threshold=0.6)
      stop ||= Stop.from_gtfs(station)
      tl_add_identifiers(stop, [station]+platforms)
      # puts "Stop: #{stop.onestop_id} / Name: #{station.name}"
      # puts "  Score: #{score} / Found: #{stop.name}"
    end
    
    # Routes
    @gtfs_by_id[:routes].each do |k,e|
      # Find: (child gtfs trips) to (child gtfs stops) to (tl stops)
      stops = children(e).map { |i| children(i) }.flatten.uniq.map { |i| @gtfs_tl[i] }
      r = Route.from_gtfs(e, stops)
      # Find all shapes...
      r[:geometry] = Route::GEOFACTORY.multi_line_string(
        children(e).map { |i| i.shape_id }.uniq.map { |i| @shape_by_id[i] }
      )
      tl_add_identifiers(r, e)
      tl_add_serves(r, stops)
      # puts "Route: #{r.onestop_id} / Name: #{r.name}"
    end

    # Operators
    operators = []
    @feed.operators_in_feed.each do |oif| 
      e = @gtfs_by_id[:agencies][oif['gtfs_agency_id']]
      next unless e
      # Find: (child gtfs routes) to (tl routes)
      routes = children(e).map { |i| @gtfs_tl[i] }.flatten
      # Find: (tl routes) to (serves tl stops)
      stops = routes.map { |r| @tl_serves[r] }.reduce(:+)
      o = Operator.from_gtfs(e, stops, routes)
      # Override Operator onestop_id
      o.onestop_id = oif['onestop_id']
      # Add identifiers
      tl_add_identifiers(o, e)
      tl_add_serves(o, routes)
      # Add to found operators
      operators << o
    end
    # Return operators
    operators
  end
  
  def create_changeset(operators)
    chunksize = 1000
    operators = operators
    routes = operators.map { |i| @tl_serves[i] }.reduce(:+)
    stops = routes.map { |i| @tl_serves[i] }.reduce(:+)
    action = 'createUpdate'

    changeset = Changeset.create()
    
    # Operators
    operators.each_slice(chunksize).each do |chunk| 
      ChangePayload.create!(
        changeset: changeset, 
        payload: {
          changes: chunk.map { |entity| 
            {
              action: action,
              operator: {
                onestopId: entity.onestop_id,
                name: entity.name,
                identifiedBy: @tl_gtfs[entity].map { |i| "gtfs://#{@feed.onestop_id}/o/#{i.id}"},
                geometry: entity.geometry,
                tags: entity.tags || {}
              }
            }
          }        
        }
      )
    end

    # Stops
    stops.each_slice(chunksize).each do |chunk|
      ChangePayload.create!(
        changeset: changeset, 
        payload: {
          changes: stops.map { |entity| 
            {
              action: action,
              stop: {
                onestopId: entity.onestop_id,
                name: entity.name,
                identifiedBy: @tl_gtfs[entity].map { |i| "gtfs://#{@feed.onestop_id}/s/#{i.id}"},
                geometry: entity.geometry,
                tags: entity.tags || {}
              }
            }
          }        
        }
      )
    end

    # Routes
    routes.each_slice(chunksize).each do |chunk|
      ChangePayload.create!(
        changeset: changeset, 
        payload: {
          changes: routes.map { |entity| 
            {
              action: action,
              route: {
                onestopId: entity.onestop_id,
                name: entity.name,
                identifiedBy: @tl_gtfs[entity].map { |i| "gtfs://#{@feed.onestop_id}/r/#{i.id}"},
                operatedBy: @tl_served_by[entity].map(&:onestop_id).first,
                serves: @tl_serves[entity].map(&:onestop_id),
                tags: entity.tags || {},
                geometry: entity.geometry,
              }
            }
          }        
        }
      )
    end

    # trip_chunks(chunksize) do |trips|
    #   ssps = stop_pairs(trips)
    #   ChangePayload.create!(
    #     changeset: changeset,
    #     payload: {
    #       changes: ssps.map { |entity|
    #         {
    #           action: action,
    #           scheduleStopPair: entity
    #         }
    #       }
    #     }
    #   )
    # end
    
    # Apply changeset
    changeset.apply!
    
  end
  
  def agency(id)
    # Return an agency by agency_id
    @gtfs_by_id[:agencies][id]
  end

  def route(id)
    # Return a route by route_id
    @gtfs_by_id[:routes][id]
  end

  def stop(id)
    # Return a stop by stop_id
    @gtfs_by_id[:stops][id]
  end

  def trip(id)
    # Return a trip by trip_id
    @gtfs_by_id[:trips][id]
  end
    
  private
  
  def parents(entity, depth=1)
    # Return the parents of an entity
    bfs(entity, @gtfs_parents, depth=depth)
  end

  def children(entity, depth=1)
    # Return the children of an entity
    bfs(entity, @gtfs_children, depth=depth)
  end

  def bfs(current, graph, depth=1)
    # Breadth first search, to a maximum depth.
    visited = []
    queue = []
    queue << current
    (0..depth-1).each do |level|
      tovisit = []
      while queue.any?
        current = queue.shift
        graph[current].each do |adjacent|
          next if visited.include?(adjacent)
          tovisit << adjacent
          visited << adjacent
        end
      end
      queue = tovisit
    end
    visited
  end

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
  
  def trip_chunks(batchsize=1000)
    # Return chunks of trips containing approx. batchsize stop_times.
    ret = []
    chunk = []
    current = 0
    total = 0
    # Reverse sort trips
    trips = @trip_counter.sort_by { |k,v| -v }
    trips.each do |k,v|
      # puts "Current: #{current}, adding: #{v}"
      # puts "  total: #{total}, ret size: #{ret.size}"
      chunk << k
      current += v
      total += v
      if current > batchsize
        yield chunk
        chunk = []
        current = 0
      end
    end
  end
  
  def stop_pairs(trips)
    # Return all the ScheduleStopPairs for a set of trips
    # TODO: Lazy enumerator
    ret = []
    # Trip IDs
    trip_ids = Set.new trips.map(&:id)

    # Sub graph mapping trip IDs to stop_times
    trip_ids_stop_times = Hash.new {|h,k| h[k] = []}
    @gtfs.stop_times.each do |stop_time|
      next unless trip_ids.include?(stop_time.trip_id)
      trip_ids_stop_times[stop_time.trip_id] << stop_time
    end 
    
    # Process each trip
    trip_ids_stop_times.each do |trip_id, stop_times|
      # Get trip and route entities
      trip = trip(trip_id)
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
  
  def make_ssp(trip, origin, destination)
    # Generate an edge between an origin and destination for a given route/trip
    route = @gtfs_tl[route(trip.route_id)]
    origin_stop = @gtfs_tl[stop(origin.stop_id)]
    destination_stop = @gtfs_tl[stop(destination.stop_id)]
    ssp = {
      # Origin
      origin_onestop_id: origin_stop.onestop_id,
      origin_timezone: origin_stop.timezone,
      origin_arrival_time: origin.arrival_time,
      origin_departure_time: origin.departure_time,
      # Destination
      destination_onestop_id: destination_stop.onestop_id,
      destination_timezone: destination_stop.timezone,
      destination_arrival_time: destination.arrival_time,
      destination_departure_time: destination.departure_time,
      # Route
      route_onestop_id: route.onestop_id,
      # Trip
      trip: trip.id,
      trip_headsign: (origin.stop_headsign || trip.headsign),
      trip_short_name: trip.short_name,
      wheelchair_accessible: trip.wheelchair_accessible.to_i,
      # bikes_allowed: trip.bikes_allowed.to_i,
      # Stop Time
      drop_off_type: origin.drop_off_type.to_i,
      pickup_type: origin.pickup_type.to_i,
      # timepoint: origin.timepoint.to_i,
      shape_dist_traveled: origin.shape_dist_traveled.to_f
    }
    ssp.update(@service_by_id[trip.service_id])
    ssp
  end
  

  def make_service(entity)
    # Note: String.to_date is Rails, not plain Ruby.
    service = @service_by_id[entity.service_id]
    service ||= {
      service_start_date: entity.start_date.to_date,
      service_end_date: entity.end_date.to_date,
      service_days_of_week: DAYS_OF_WEEK.map { |i| !entity.send(i).to_i.zero? },
      service_added: [],
      service_except: []
    }
    date = entity.date rescue nil
    if date
      if entity.exception_type.to_i == 1
        service[:service_added] << date.to_date
      else
        service[:service_except] << date.to_date
      end
    end
    @service_by_id[entity.service_id] = service
    service
  end
    
end


if __FILE__ == $0
  Feed.update_feeds_from_feed_registry
  feed = Feed.find_by!(onestop_id: 'f-9q9-caltrain')
  filename = ARGV[0] || 'tmp/transitland-feed-data/f-9q9-caltrain.zip'
  graph = GTFSGraph.new(filename, feed)
  graph.load_graph
  operators = graph.load_tl
  graph.create_changeset operators
end

