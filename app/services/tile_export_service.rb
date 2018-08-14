module TileExportService
  BBOX_PADDING = 0.1
  KEY_QUEUE_STOPS = 'queue_stops'
  KEY_QUEUE_SCHEDULES = 'queue_schedules'
  KEY_STOPID_GRAPHID = 'stopid_graphid'
  IMPORT_LEVEL = 4
  GRAPH_LEVEL = 2
  STOP_PAIRS_TILE_LIMIT = 500_000

  # kTransitEgress = 4,           // Transit egress
  # kTransitStation = 5,          // Transit station
  # kMultiUseTransitPlatform = 6, // Multi-use transit platform (rail and bus)
  NODE_TYPES = {
    2 => 4,
    1 => 5,
    0 => 6
  }

  VT = Valhalla::Mjolnir::Transit::VehicleType
  VEHICLE_TYPES = {
    tram: VT::Tram,
    tram_service: VT::Tram,
    metro: VT::Metro,
    rail: VT::Rail,
    suburban_railway: VT::Rail,
    bus: VT::Bus,
    trolleybys_service: VT::Bus,
    express_bus_service: VT::Bus,
    local_bus_service: VT::Bus,
    bus_service: VT::Bus,
    shuttle_bus: VT::Bus,
    demand_and_response_bus_service: VT::Bus,
    regional_bus_service: VT::Bus,
    ferry: VT::Ferry,
    cablecar: VT::CableCar,
    gondola: VT::Gondola,
    funicular: VT::Funicular
  }

  class TileValueError < StandardError
  end

  class OriginEqualsDestinationError < TileValueError
  end

  class MissingGraphIDError < TileValueError
  end

  class MissingRouteError < TileValueError
  end

  class MissingShapeError < TileValueError
  end

  class MissingTripError < TileValueError
  end

  class InvalidTimeError < TileValueError
  end

  class TileBuilder
    attr_accessor :tile
    def initialize(tilepath, tile, feed_version_ids: nil)
      @tilepath = tilepath
      @tile = tile
      # filters
      @feed_version_ids = feed_version_ids || []
      # globally unique indexes
      @stopid_graphid ||= {}
      @graphid_stopid ||= {}
      @trip_index ||= TileUtils::DigestIndex.new(bits: 24)
      @block_index ||= TileUtils::DigestIndex.new(start: 1, bits: 20)
      # tile unique indexes
      @route_index = {}
      @shape_index = {}
    end

    def log(msg)
      puts "tile #{@tile}: #{msg}"
    end

    def debug(msg)
      puts "tile #{@tile} debug: #{msg}"
    end

    def build_stops
      # TODO:
      #    max graph_ids in a tile
      t = Time.now

      # New tile
      tileset = TileUtils::TileSet.new(@tilepath)
      tile = tileset.new_tile(GRAPH_LEVEL, @tile)

      GTFSStop
        .where(feed_version_id: @feed_version_ids)
        .where(parent_station_id: nil)
        .geometry_within_bbox(bbox_padded(tile.bbox))
        .includes(:children)
        .find_each do |stop|

        # Check if stop is inside tile
        stop_tile = TileUtils::GraphID.new(level: GRAPH_LEVEL, lon: stop.stop_lon, lat: stop.stop_lat).tile
        if stop_tile != @tile
          # debug("skipping stop #{stop.id}: coordinates #{stop.coordinates.join(',')} map to tile #{stop_tile} outside of tile #{@tile}")
          next
        end

        # Station references
        prev_type_graphid = nil

        # Egresses
        stop_egresses = [] # stop.stop_egresses.to_a
        (stop_egresses << GTFSStop.new(stop.attributes)) if stop_egresses.empty? # generated egress
        stop_egresses.each do |stop_egress|
          stop_egress.location_type = 2
          node = make_node(stop_egress)
          node.graphid = TileUtils::GraphID.new(level: GRAPH_LEVEL, tile: @tile, index: tile.message.nodes.size).value
          node.prev_type_graphid = prev_type_graphid if prev_type_graphid
          prev_type_graphid ||= node.graphid
          tile.message.nodes << node
        end

        # Station
        stop.location_type = 1
        node = make_node(stop)
        node.graphid = TileUtils::GraphID.new(level: GRAPH_LEVEL, tile: @tile, index: tile.message.nodes.size).value
        node.prev_type_graphid = prev_type_graphid if prev_type_graphid
        prev_type_graphid = node.graphid
        tile.message.nodes << node

        # Platforms
        stop_platforms = stop.children.to_a
        (stop_platforms << GTFSStop.new(stop.attributes)) if stop_platforms.empty? 
        stop_platforms.each do |stop_platform|
          stop_platform.location_type = 0
          node = make_node(stop_platform)
          node.graphid = TileUtils::GraphID.new(level: GRAPH_LEVEL, tile: @tile, index: tile.message.nodes.size).value
          node.prev_type_graphid = prev_type_graphid if prev_type_graphid # station_id graphid
          @stopid_graphid[stop_platform.id] = node.graphid
          @graphid_stopid[node.graphid] = stop_platform.id
          tile.message.nodes << node
        end
      end

      # Write tile
      nodes_size = tile.message.nodes.size
      tileset.write_tile(tile) if nodes_size > 0
      t = Time.now - t
      log("nodes: #{nodes_size} time: #{t.round(2)} (#{(nodes_size/t).to_i} nodes/s)")
      return nodes_size
    end

    def build_schedules
      # Get stop_ids
      t = Time.now
      tileset = TileUtils::TileSet.new(@tilepath)
      base_tile = tileset.read_tile(GRAPH_LEVEL, @tile)
      stop_ids = base_tile.message.nodes.map { |node| @graphid_stopid[node.graphid] }.compact
      trips = {}
      calendars = {}

      # Build stop_pairs for each stop_id
      tile_ext = 0
      stop_pairs_tile = base_tile # tileset.new_tile(GRAPH_LEVEL, @tile)
      stop_pairs_total = 0
      errors = Hash.new(0)
      stop_ids.each do |stop_id|
        puts "stop_id: #{stop_id}"
        stop_pairs_stop_id_count = 0
        GTFSStopTime
          .where(stop_id: stop_id)
          .find_in_batches do |ssps|

          # Skip the last stop_time in a trip
          ssps = ssps.select(&:destination_id)

          # Cache: Get unseen trips
          trip_ids = ssps.map(&:trip_id).select { |t| !trips.key?(t) }
          GTFSTrip.find(trip_ids).each do |t|
            trips[t.id] = t
          end
          ssps.each { |ssp| ssp.trip = trips[ssp.trip_id] }

          # Cache: Get unseen calendars and calendar_dates
          ssps.each do |ssp|
            # if we don't have the calendar cached, find the calendar or create an empty one
            args = {feed_version_id: ssp.trip.feed_version_id, service_id: ssp.trip.service_id}
            key = [ssp.trip.feed_version_id, ssp.trip.service_id]
            calendar = calendars[key]
            if calendar.nil?
              calendar = GTFSCalendar.find_by(args) # || GTFSCalendar.new(args)
            end
            calendar.start_date ||= calendar.service_added_dates.min
            calendar.end_date ||= calendar.service_added_dates.max
            ssp.trip.calendar = calendar
            calendars[key] = calendar
          end

          # Get unvisited routes for this batch, add to tile
          route_ids = ssps.map { |ssp| ssp.trip.route_id }.select { |route_id| !@route_index.key?(route_id) }.uniq
          ssps.each { |ssp| @route_index[ssp.trip.route_id] ||= nil } # set as visited
          if route_ids.size > 0
            GTFSRoute.where(id: route_ids).find_each do |route| # get unvisited
              @route_index[route.id] = base_tile.message.routes.size
              debug("route: #{route.id} -> #{@route_index[route.id]}")
              base_tile.message.routes << make_route(route)
            end
          end

          # Get unseen shapes for this batch, add to tile
          shape_ids = ssps.map { |ssp| ssp.trip.shape_id }.select { |shape_id| !@shape_index.key?(shape_id) }.uniq
          ssps.each { |ssp| @shape_index[ssp.trip.shape_id] ||= nil } # set as visited
          if shape_ids.size > 0
            GTFSShape.where(id: shape_ids).find_each do |shape|
              pshape = make_shape(shape)
              pshape.shape_id = base_tile.message.shapes.size + 1
              @shape_index[shape.id] = pshape.shape_id
              debug("shape: #{shape.id} -> #{@shape_index[shape.id]}")
              base_tile.message.shapes << pshape
            end
          end

          # Process each ssp
          ssps.each do |ssp|
            # process ssp and count errors
            begin
              i = make_stop_pair(ssp)
            rescue TileValueError => e
              errors[e.class.name.to_sym] += 1
              log("error: ssp #{ssp.id}: #{e}")
            rescue StandardError => e
              errors[e.class.name.to_sym] += 1
              log("error: ssp #{ssp.id}: #{e}")
            end
            next unless i
            stop_pairs_tile.message.stop_pairs << i
            stop_pairs_stop_id_count += 1
            stop_pairs_total += 1
          end

          # Write supplement tile, start new tile
          if stop_pairs_tile.message.stop_pairs.size > STOP_PAIRS_TILE_LIMIT
            if stop_pairs_tile != base_tile
              debug("writing tile ext #{tile_ext}: #{stop_pairs_tile.message.stop_pairs.size} stop_pairs")
              tileset.write_tile(stop_pairs_tile, ext: tile_ext)
              tile_ext += 1
            end
            stop_pairs_tile = tileset.new_tile(GRAPH_LEVEL, @tile)
          end
        end
        # Done for this stop
        debug("stop_pairs for stop_id #{stop_id}: #{stop_pairs_stop_id_count}")
      end

      # Write dangling supplement tile
      if stop_pairs_tile != base_tile && stop_pairs_tile.message.stop_pairs.size > 0
        debug("writing tile ext #{tile_ext}: #{stop_pairs_tile.message.stop_pairs.size} stop_pairs")
        tileset.write_tile(stop_pairs_tile, ext: tile_ext)
      end

      # Write the base tile
      debug("writing tile base: #{base_tile.message.nodes.size} nodes, #{base_tile.message.routes.size} routes, #{base_tile.message.shapes.size} shapes, #{base_tile.message.stop_pairs.size} stop_pairs (#{stop_pairs_total} tile total)")
      tileset.write_tile(base_tile)

      # Write tile
      t = Time.now - t
      error_txt = ([errors.values.sum.to_s] + errors.map { |k,v| "#{k}: #{v}" }).join(' ')
      log("#{base_tile.message.nodes.size} nodes, #{base_tile.message.routes.size} routes, #{base_tile.message.shapes.size} shapes, #{stop_pairs_total} stop_pairs, errors #{error_txt}, time: #{t.round(2)} (#{(stop_pairs_total/t).to_i} stop_pairs/s)")
      return stop_pairs_total
    end

    private

    def seconds_since_midnight(value)
      h,m,s = value.split(':').map(&:to_i)
      h * 3600 + m * 60 + s
    end

    def color_to_int(value)
      match = /(\h{6})/.match(value.to_s)
      match ? match[0].to_i(16) : nil
    end

    # bbox padding
    def bbox_padded(bbox)
      ymin, xmin, ymax, xmax = bbox
      padding = BBOX_PADDING
      [ymin-padding, xmin-padding, ymax+padding, xmax+padding]
    end

    # make entity methods
    def make_stop_pair(ssp)
      # TODO:
      #   skip if origin_departure_time < frequency_start_time
      #   skip if bad time information
      #   add < and > to onestop_ids
      trip = ssp.trip
      calendar = ssp.trip.calendar
      destination_graphid = @stopid_graphid[ssp.destination_id]
      origin_graphid = @stopid_graphid[ssp.stop_id]
      route_index = @route_index[trip.route_id]
      shape_id = @shape_index[trip.shape_id]

      fail InvalidTimeError.new("missing calendar for trip #{trip.trip_id}") unless calendar
      fail OriginEqualsDestinationError.new("origin_graphid #{origin_graphid} == destination_graphid #{destination_graphid}") if origin_graphid == destination_graphid
      fail MissingGraphIDError.new("missing origin_graphid for stop #{ssp.stop_id}") unless origin_graphid
      fail MissingGraphIDError.new("missing destination_graphid for stop #{ssp.destination_id}") unless destination_graphid
      fail MissingRouteError.new("missing route_index for route #{trip.route_id}") unless route_index
      fail MissingShapeError.new("missing shape for shape #{trip.shape_id}") unless shape_id
      fail InvalidTimeError.new("origin_departure_time #{ssp.departure_time} > destination_arrival_time #{ssp.destination_arrival_time}") if ssp.departure_time > ssp.destination_arrival_time

      # Make SSP
      params = {}
      # bool bikes_allowed = 1;
      (params[:bikes_allowed] = true) if trip.bikes_allowed == 1
      # uint32 block_id = 2;
      (params[:block_id] = @block_index.check(trip.block_id)) if trip.block_id
      # uint32 destination_arrival_time = 3;
      params[:destination_arrival_time] = ssp.destination_arrival_time
      # uint64 destination_graphid = 4;
      params[:destination_graphid] = destination_graphid
      # string destination_onestop_id = 5;
      # params[:destination_onestop_id] = nil # TODO
      # string operated_by_onestop_id = 6;
      # params[:operated_by_onestop_id] = nil # TODO
      # uint32 origin_departure_time = 7;
      params[:origin_departure_time] = ssp.departure_time
      # uint64 origin_graphid = 8;
      params[:origin_graphid] = origin_graphid
      # string origin_onestop_id = 9;
      # params[:origin_onestop_id] = nil # TODO
      # uint32 route_index = 10;
      params[:route_index] = route_index
      # repeated uint32 service_added_dates = 11;
      params[:service_added_dates] = calendar.service_added_dates.map(&:jd)
      # repeated bool service_days_of_week = 12;
      params[:service_days_of_week] = calendar.service_days_of_week
      # uint32 service_end_date = 13;
      params[:service_end_date] = calendar.end_date.jd
      # repeated uint32 service_except_dates = 14;
      params[:service_except_dates] = calendar.service_except_dates.map(&:jd)
      # uint32 service_start_date = 15;
      params[:service_start_date] = calendar.start_date.jd
      # string trip_headsign = 16;
      params[:trip_headsign] = ssp.stop_headsign || trip.trip_headsign
      # uint32 trip_id = 17;
      params[:trip_id] = @trip_index.check(trip.id)
      # bool wheelchair_accessible = 18;
      (params[:wheelchair_accessible] = true) if trip.wheelchair_accessible == 1
      # uint32 shape_id = 20;
      params[:shape_id] = shape_id
      # float origin_dist_traveled = 21;
      (params[:origin_dist_traveled] = ssp.shape_dist_traveled) if ssp.shape_dist_traveled
      # float destination_dist_traveled = 22;
      # params[:destination_dist_traveled] = nil #  ssp.destination_dist_traveled if ssp.destination_dist_traveled
      # TODO: frequencies
      # puts params
      Valhalla::Mjolnir::Transit::StopPair.new(params)
    end

    def make_shape(shape)
      params = {}
      # uint32 shape_id = 1;
      # bytes encoded_shape = 2;
      #   reverse coordinates
      reversed = shape.geometry[:coordinates].map { |a,b| [b,a] }
      params[:encoded_shape] = TileUtils::Shape7.encode(reversed)
      Valhalla::Mjolnir::Transit::Shape.new(params)
    end

    def make_route(route)
      # TODO:
      #   skip if unknown vehicle_type
      params = {}
      # string name = 1;
      params[:name] = route.name
      # string onestop_id = 2;
      # params[:onestop_id] = nil # TODO
      # string operated_by_name = 3;
      params[:operated_by_name] = route.agency.agency_name
      # string operated_by_onestop_id = 4;
      # params[:operated_by_onestop_id] = nil # TODO
      # string operated_by_website = 5;
      params[:operated_by_website] = route.agency.agency_url
      # uint32 route_color = 6;
      params[:route_color] = color_to_int(route.route_color || 'FFFFFF')
      # string route_desc = 7;
      params[:route_desc] = route.route_desc
      # string route_long_name = 8;
      params[:route_long_name] = route.route_long_name
      # uint32 route_text_color = 9;
      params[:route_text_color] = color_to_int(route.route_text_color)
      # VehicleType vehicle_type = 10;
      params[:vehicle_type] = VT::Bus # TODO
      Valhalla::Mjolnir::Transit::Route.new(params.compact)
    end

    def make_node(stop)
      params = {}
      # float lon = 1;
      params[:lon] = stop.stop_lon
      # float lat = 2;
      params[:lat] = stop.stop_lat
      # uint32 type = 3;
      params[:type] = NODE_TYPES[stop.location_type]
      # uint64 graphid = 4;
      # set in build_stops
      # uint64 prev_type_graphid = 5;
      # set in build_stops
      # string name = 6;
      params[:name] = stop.stop_name
      # string onestop_id = 7;
      # params[:onestop_id] = nil # TODO
      # uint64 osm_way_id = 8;
      # params[:osm_way_id] = nil # TODO
      # string timezone = 9;
      params[:timezone] = stop.stop_timezone || 'America/Los_Angeles'
      # bool wheelchair_boarding = 10;
      params[:wheelchair_boarding] = true
      # bool generated = 11;
      if stop.location_type == 2
        # params[:onestop_id] = "#{onestop_id}>"
        params[:generated] = true
      end
      if stop.location_type == 0
        # params[:onestop_id] = "#{onestop_id}<"
        # params[:generated] = true # not set for platforms
      end
      # uint32 traversability = 12;
      if stop.location_type == 2 # TODO: check
        params[:traversability] = 3 
      end
      Valhalla::Mjolnir::Transit::Node.new(params.compact)
    end
  end

  def self.tile_build_stops(tilepath, feed_version_ids: nil)
    redis = Redis.new
    while tile = redis.rpop(KEY_QUEUE_STOPS)
      tile = tile.to_i
      builder = TileBuilder.new(tilepath, tile, feed_version_ids: feed_version_ids)
      nodes_size = builder.build_stops
      if nodes_size > 0
        redis.rpush(KEY_QUEUE_SCHEDULES, tile)
        stopid_graphid = builder.instance_variable_get('@stopid_graphid')
        stopid_graphid.each_slice(1000) { |i| redis.hmset(KEY_STOPID_GRAPHID, i.flatten) }
      end
      remaining = redis.llen(KEY_QUEUE_STOPS)
      puts "remaining: ~#{remaining}"
    end
  end

  def self.tile_build_schedules(tilepath, feed_version_ids: nil)
    # stopid_graphid
    stopid_graphid = {}
    graphid_stopid = {}
    redis = Redis.new
    cursor = nil
    while cursor != '0'
      cursor, data = redis.hscan(KEY_STOPID_GRAPHID, cursor, count: 1_000)
      data.each do |k,v|
        k = k.to_i
        v = v.to_i
        stopid_graphid[k] = v
        graphid_stopid[v] = k
      end
    end
    # queue
    while tile = redis.rpop(KEY_QUEUE_SCHEDULES)
      tile = tile.to_i
      builder = TileBuilder.new(tilepath, tile, feed_version_ids: feed_version_ids)
      builder.instance_variable_set('@stopid_graphid', stopid_graphid)
      builder.instance_variable_set('@graphid_stopid', graphid_stopid)
      builder.build_schedules
      remaining = redis.llen(KEY_QUEUE_SCHEDULES)
      puts "remaining: ~#{remaining}"
    end
  end

  def self.export_tiles(tilepath, thread_count: nil, feeds: nil, feed_versions: nil, tiles: nil)
    # Debug
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Base.logger.level = Logger::DEBUG

    # Filter by feed/feed_version
    # feed_version_ids = []
    # if feed_versions
    #   feed_version_ids = feed_versions.map(&:id)
    # elsif feeds
    #   feed_version_ids = feeds.map(&:active_feed_version_id)
    # else
    #   feed_version_ids = Feed.where_active_feed_version_import_level(IMPORT_LEVEL).pluck(:active_feed_version_id)
    # end
    feed_version_ids = [3] # FeedVersion.pluck(:id)

    # Build bboxes
    puts "Selecting tiles..."
    count_stops = Set.new
    stop_platforms = Hash.new { |h,k| h[k] = Set.new }
    stop_egresses = Hash.new { |h,k| h[k] = Set.new }
    tiles = Set.new(tiles)
    if tiles.empty?
      count = 1
      total = feed_version_ids.size
      FeedVersion.where(id: feed_version_ids).includes(:feed).find_each do |feed_version|
        feed = feed_version.feed
        fvtiles = Set.new
        GTFSStop.where(feed_version: feed_version).find_each do |stop|
          if stop.parent_station_id.nil?
            count_stops << stop.id
            fvtiles << TileUtils::GraphID.new(level: GRAPH_LEVEL, lon: stop.stop_lon, lat: stop.stop_lat).tile
          else
            stop_platforms[stop.parent_station_id] << stop.id
          end
        end
        puts "\t(#{count}/#{total}) #{feed_version.feed.onestop_id} #{feed_version.sha1}: #{fvtiles.size} tiles"
        tiles += fvtiles
        count += 1
      end
    end

    # TODO: Filter stop_platforms/stop_egresses by feed_version
    count_egresses = count_stops.map { |i| stop_egresses[i].empty? ? 1 : stop_egresses[i].size }.sum
    count_platforms = count_stops.map { |i| stop_platforms[i].empty? ? 1 : stop_platforms[i].size }.sum
    puts "Tiles to build: #{tiles.size}"
    puts "Expected:"
    puts "\tstops: #{count_stops.size}"
    puts "\tplatforms: #{stop_platforms.map { |k,v| v.size }.sum}"
    puts "\tegresses: #{stop_egresses.map { |k,v| v.size }.sum}"
    puts "\tnodes: #{count_stops.size + count_egresses + count_platforms}"
    puts "\tstopid-graphid: #{count_platforms}"

    # Setup queue
    thread_count ||= 1
    redis = Redis.new
    redis.del(KEY_QUEUE_STOPS)
    redis.del(KEY_QUEUE_SCHEDULES)
    redis.del(KEY_STOPID_GRAPHID)
    tiles.each_slice(1000) { |i| redis.rpush(KEY_QUEUE_STOPS, i) }

    # Build stops for each tile.
    puts "\n===== Stops =====\n"
    workers = (0...thread_count).map do
      fork { tile_build_stops(tilepath, feed_version_ids: feed_version_ids) }
    end
    workers.each { |pid| Process.wait(pid) }

    puts "\nStops finished. Schedule tile queue: #{redis.llen(KEY_QUEUE_SCHEDULES)} stopid-graphid mappings: #{redis.hlen(KEY_STOPID_GRAPHID)}"

    # Build schedule, routes, shapes for each tile.
    puts "\n===== Routes, Shapes, StopPairs =====\n"
    workers = (0...thread_count).map do
      fork { tile_build_schedules(tilepath, feed_version_ids: feed_version_ids) }
    end
    workers.each { |pid| Process.wait(pid) }

    puts "Done!"
  end
end
