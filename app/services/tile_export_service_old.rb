module TileExportServiceOld
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
    StopEgress: 4,
    Stop: 5,
    StopPlatform: 6
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

      Stop
        .where_imported_from_feed_version(@feed_version_ids)
        .where(parent_stop: nil)
        .geometry_within_bbox(bbox_padded(tile.bbox))
        .includes(:stop_platforms, :stop_egresses)
        .find_each do |stop|

        # Check if stop is inside tile
        stop_tile = TileUtils::GraphID.new(level: GRAPH_LEVEL, lon: stop.coordinates[0], lat: stop.coordinates[1]).tile
        if stop_tile != @tile
          # debug("skipping stop #{stop.id}: coordinates #{stop.coordinates.join(',')} map to tile #{stop_tile} outside of tile #{@tile}")
          next
        end

        # Station references
        prev_type_graphid = nil

        # Egresses
        stop_egresses = stop.stop_egresses.to_a
        stop_egresses << StopEgress.new(stop.attributes) if stop_egresses.empty? # generated egress
        stop_egresses.each do |stop_egress|
          node = make_node(stop_egress)
          node.graphid = TileUtils::GraphID.new(level: GRAPH_LEVEL, tile: @tile, index: tile.message.nodes.size).value
          node.prev_type_graphid = prev_type_graphid if prev_type_graphid
          prev_type_graphid ||= node.graphid
          tile.message.nodes << node
        end

        # Station
        node = make_node(stop)
        node.graphid = TileUtils::GraphID.new(level: GRAPH_LEVEL, tile: @tile, index: tile.message.nodes.size).value
        node.prev_type_graphid = prev_type_graphid if prev_type_graphid
        prev_type_graphid = node.graphid
        tile.message.nodes << node

        # Platforms
        stop_platforms = stop.stop_platforms.to_a
        (stop_platforms << StopPlatform.new(stop.attributes)) if stop_platforms.empty? # station ssps
        stop_platforms.each do |stop_platform|
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

      # Build stop_pairs for each stop_id
      tile_ext = 0
      stop_pairs_tile = base_tile # tileset.new_tile(GRAPH_LEVEL, @tile)
      stop_pairs_total = 0
      errors = Hash.new(0)
      stop_ids.each do |stop_id|
        stop_pairs_stop_id_count = 0
        ScheduleStopPair
          .where(origin_id: stop_id)
          .includes(:origin, :destination, :operator)
          .find_in_batches do |ssps|
          # Evaluate by active feed version - faster than join or where in (?)
          ssps = ssps.select { |ssp| @feed_version_ids.include?(ssp.feed_version_id) }

          # Get unvisited routes for this batch
          route_ids = ssps.map(&:route_id).select { |route_id| !@route_index.key?(route_id) }
          ssps.each { |ssp| @route_index[ssp.route_id] ||= nil } # set as visited
          Route.where(id: route_ids).find_each do |route| # get unvisited
            @route_index[route.id] = base_tile.message.routes.size
            debug("route: #{route.id} -> #{@route_index[route.id]}")
            base_tile.message.routes << make_route(route)
          end

          # Get unseen rsps for this batch
          rsp_ids = ssps.map(&:route_stop_pattern_id).select { |rsp_id| !@shape_index.key?(rsp_id) }
          ssps.each { |ssp| @shape_index[ssp.route_stop_pattern_id] ||= nil } # set as visited
          RouteStopPattern.where(id: rsp_ids).find_each do |rsp|
            shape = make_shape(rsp)
            shape.shape_id = base_tile.message.shapes.size + 1
            @shape_index[rsp.id] = shape.shape_id
            debug("shape: #{rsp.id} -> #{@shape_index[rsp.id]}")
            base_tile.message.shapes << shape
          end

          # Process each ssp
          ssps.each do |ssp|
            # process ssp and count errors
            begin
              stop_pairs_tile.message.stop_pairs << make_stop_pair(ssp)
              stop_pairs_stop_id_count += 1
              stop_pairs_total += 1
            rescue TileValueError => e
              errors[e.class.name.to_sym] += 1
              log("error: ssp #{ssp.id}: #{e}")
            rescue StandardError => e
              errors[e.class.name.to_sym] += 1
              log("error: ssp #{ssp.id}: #{e}")
            end
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
      destination_graphid = @stopid_graphid[ssp.destination_id]
      origin_graphid = @stopid_graphid[ssp.origin_id]
      fail OriginEqualsDestinationError.new("origin_graphid #{origin_graphid} == destination_graphid #{destination_graphid}") if origin_graphid == destination_graphid
      fail MissingGraphIDError.new("missing origin_graphid for stop #{ssp.origin_id}") unless origin_graphid
      fail MissingGraphIDError.new("missing destination_graphid for stop #{ssp.destination_id}") unless destination_graphid

      route_index = @route_index[ssp.route_id]
      fail MissingRouteError.new("missing route_index for route #{ssp.route_id}") unless route_index

      shape_id = @shape_index[ssp.route_stop_pattern_id]
      fail MissingShapeError.new("missing shape for rsp #{ssp.route_stop_pattern_id}") unless shape_id

      trip_id = @trip_index.check(ssp.trip)
      fail MissingTripError.new("missing trip_id for trip #{ssp.trip}") unless trip_id

      destination_arrival_time = seconds_since_midnight(ssp.destination_arrival_time)
      origin_departure_time = seconds_since_midnight(ssp.origin_departure_time)
      fail InvalidTimeError.new("origin_departure_time #{origin_departure_time} > destination_arrival_time #{destination_arrival_time}") if origin_departure_time > destination_arrival_time

      block_id = @block_index.check(ssp.block_id)

      # Make SSP
      params = {}
      # bool bikes_allowed = 1;
      # uint32 block_id = 2;
      # params[:block_id] = block_id
      # uint32 destination_arrival_time = 3;
      params[:destination_arrival_time] = destination_arrival_time
      # uint64 destination_graphid = 4;
      params[:destination_graphid] = destination_graphid
      # string destination_onestop_id = 5;
      params[:destination_onestop_id] = ssp.destination.onestop_id
      # string operated_by_onestop_id = 6;
      params[:operated_by_onestop_id] = ssp.operator.onestop_id
      # uint32 origin_departure_time = 7;
      params[:origin_departure_time] = origin_departure_time
      # uint64 origin_graphid = 8;
      params[:origin_graphid] = origin_graphid
      # string origin_onestop_id = 9;
      params[:origin_onestop_id] = ssp.origin.onestop_id
      # uint32 route_index = 10;
      params[:route_index] = route_index
      # repeated uint32 service_added_dates = 11;
      params[:service_added_dates] = ssp.service_added_dates.map(&:jd)
      # repeated bool service_days_of_week = 12;
      params[:service_days_of_week] = ssp.service_days_of_week
      # uint32 service_end_date = 13;
      params[:service_end_date] = ssp.service_end_date.jd
      # repeated uint32 service_except_dates = 14;
      params[:service_except_dates] = ssp.service_except_dates.map(&:jd)
      # uint32 service_start_date = 15;
      params[:service_start_date] = ssp.service_start_date.jd
      # string trip_headsign = 16;
      params[:trip_headsign] = ssp.trip_headsign
      # uint32 trip_id = 17;
      params[:trip_id] = trip_id
      # bool wheelchair_accessible = 18;
      params[:wheelchair_accessible] = true # !!(ssp.wheelchair_accessible)
      # uint32 shape_id = 20;
      params[:shape_id] = shape_id
      # float origin_dist_traveled = 21;
      params[:origin_dist_traveled] = ssp.origin_dist_traveled if ssp.origin_dist_traveled
      # float destination_dist_traveled = 22;
      params[:destination_dist_traveled] = ssp.destination_dist_traveled if ssp.destination_dist_traveled
      if ssp.frequency_headway_seconds
        # protobuf doesn't define frequency_start_time
        # uint32 frequency_end_time = 23;
        params[:frequency_end_time] = seconds_since_midnight(ssp.frequency_end_time)
        # uint32 frequency_headway_seconds = 24;
        params[:frequency_headway_seconds] = ssp.frequency_headway_seconds
      end
      Valhalla::Mjolnir::Transit::StopPair.new(params)
    end

    def make_shape(rsp)
      params = {}
      # uint32 shape_id = 1;
      # bytes encoded_shape = 2;
      #   reverse coordinates
      reversed = rsp.geometry[:coordinates].map { |a,b| [b,a] }
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
      params[:onestop_id] = route.onestop_id
      # string operated_by_name = 3;
      params[:operated_by_name] = route.operator.name
      # string operated_by_onestop_id = 4;
      params[:operated_by_onestop_id] = route.operator.onestop_id
      # string operated_by_website = 5;
      params[:operated_by_website] = route.operator.website
      # uint32 route_color = 6;
      params[:route_color] = color_to_int(route.color || 'FFFFFF')
      # string route_desc = 7;
      params[:route_desc] = route.tags["route_desc"]
      # string route_long_name = 8;
      params[:route_long_name] = route.tags["route_long_name"] || route.name
      # uint32 route_text_color = 9;
      params[:route_text_color] = color_to_int(route.tags["route_text_color"])
      # VehicleType vehicle_type = 10;
      params[:vehicle_type] = VEHICLE_TYPES[route.vehicle_type.to_sym] || VT::Bus
      Valhalla::Mjolnir::Transit::Route.new(params.compact)
    end

    def make_node(stop)
      params = {}
      # float lon = 1;
      params[:lon] = stop.coordinates[0]
      # float lat = 2;
      params[:lat] = stop.coordinates[1]
      # uint32 type = 3;
      params[:type] = NODE_TYPES[stop.class.name.to_sym]
      # uint64 graphid = 4;
      # set in build_stops
      # uint64 prev_type_graphid = 5;
      # set in build_stops
      # string name = 6;
      params[:name] = stop.name
      # string onestop_id = 7;
      params[:onestop_id] = stop.onestop_id
      # uint64 osm_way_id = 8;
      params[:osm_way_id] = stop.osm_way_id
      # string timezone = 9;
      params[:timezone] = stop.timezone
      # bool wheelchair_boarding = 10;
      params[:wheelchair_boarding] = true
      # bool generated = 11;
      if stop.instance_of?(StopEgress) && !stop.persisted?
        params[:onestop_id] = "#{stop.onestop_id}>"
        params[:generated] = true
      end
      if stop.instance_of?(StopPlatform) && !stop.persisted?
        params[:onestop_id] = "#{stop.onestop_id}<"
        # params[:generated] = true # not set for platforms
      end
      # uint32 traversability = 12;
      if stop.instance_of?(StopEgress)
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
    # ActiveRecord::Base.logger = Logger.new(STDOUT)
    # ActiveRecord::Base.logger.level = Logger::DEBUG

    # Avoid autoload issues in threads
    Stop.connection
    StopPlatform.connection
    StopEgress.connection
    Route.connection
    Operator.connection
    RouteStopPattern.connection
    EntityImportedFromFeed.connection
    ScheduleStopPair.connection

    # Filter by feed/feed_version
    feed_version_ids = []
    if feed_versions
      feed_version_ids = feed_versions.map(&:id)
    elsif feeds
      feed_version_ids = feeds.map(&:active_feed_version_id)
    else
      feed_version_ids = Feed.where_active_feed_version_import_level(IMPORT_LEVEL).pluck(:active_feed_version_id)
    end

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
        Stop.where_imported_from_feed_version(feed_version).find_each do |stop|
            if stop.is_a?(StopPlatform)
              stop_platforms[stop.parent_stop_id] << stop.id
            elsif stop.is_a?(StopEgress)
              stop_egresses[stop.parent_stop_id] << stop.id
            else
              count_stops << stop.id
              fvtiles << TileUtils::GraphID.new(level: GRAPH_LEVEL, lon: stop.coordinates[0], lat: stop.coordinates[1]).tile
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

    # Clear
    count_stops.clear
    stop_platforms.clear
    stop_egresses.clear
    # stopid_graphid = Hash[redis.hgetall('stopid_graphid').map { |k,v| [k.to_i, v.to_i] }]
    # expected_stops = Set.new
    # count_stops.each { |i| expected_stops += (stop_platforms[i].empty? ? [i].to_set : stop_platforms[i]) }
    # missing = stopid_graphid.keys.to_set - expected_stops

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