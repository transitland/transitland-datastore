# ActiveRecord::Base.logger = Logger.new(STDOUT)
# ActiveRecord::Base.logger.level = Logger::DEBUG

load 'lib/proto/tile_set.rb'

EPOCH = Date.parse('1970-01-01')
IMPORT_LEVEL = 4
LEVEL = 2
STOPID_GRAPHID = {}
GRAPHID_STOPID = {}

# kTransitEgress = 4,           // Transit egress
# kTransitStation = 5,          // Transit station
# kMultiUseTransitPlatform = 6, // Multi-use transit platform (rail and bus)
NODE_TYPES = {
  StopEgress: 4,
  Stop: 5,
  StopPlatform: 6
}

def time_to_seconds(value)
  h,m,s = value.split(':').map(&:to_i)
  h * 3600 + m * 60 + s
end

def date_to_days(value)
  (value - EPOCH).to_i
end

def color_to_int(value)
  0
end

class TileBuilder
  def initialize(tile)
    @tile = tile
    @bbox = tile.bbox
  end

  def bbox_padded
    ymin, xmin, ymax, xmax = @tile.bbox
    padding = 0.0
    [ymin-padding, xmin, ymax+padding, xmax]
  end

  def build_stops
    puts "Building stops: #{@tile.tile}"

    # Stops
    stopid_stopindex = {}
    stop_index = 0
    Stop.where(parent_stop: nil).geometry_within_bbox(bbox_padded).order(id: :asc).includes(:stop_platforms, :stop_egresses).each do |stop|
      # Check if stop is inside tile
      next if GraphID.new(level: LEVEL, lon: stop.coordinates[0], lat: stop.coordinates[1]).tile != @tile.tile
      puts "\tstop: #{stop.onestop_id}"

      # Station references
      prev_type_graphid = nil

      # Egresses
      stop_egresses = stop.stop_egresses.to_a
      stop_egresses << StopEgress.new(stop.attributes) if stop_egresses.empty? # generated egress
      stop_egresses.each do |stop_egress|
        node = make_node(stop_egress)
        node.type = NODE_TYPES[StopEgress.name.to_sym]
        node.graphid = GraphID.new(level: LEVEL, tile: @tile.tile, index: stop_index).value
        node.prev_type_graphid = prev_type_graphid if prev_type_graphid
        prev_type_graphid = node.graphid
        stop_index += 1
        @tile.message.nodes << node
      end

      # Station
      node = make_node(stop)
      node.type = NODE_TYPES[Stop.name.to_sym]
      node.graphid = GraphID.new(level: LEVEL, tile: @tile.tile, index: stop_index).value
      node.prev_type_graphid = prev_type_graphid if prev_type_graphid
      prev_type_graphid = node.graphid
      stop_index += 1
      @tile.message.nodes << node

      # Platforms
      stop_platforms = stop.stop_platforms.to_a
      stop_platforms << StopPlatform.new(stop.attributes) # station ssps
      stop_platforms.each do |stop_platform|
        node = make_node(stop_platform)
        node.type = NODE_TYPES[StopPlatform.name.to_sym]
        node.graphid = GraphID.new(level: LEVEL, tile: @tile.tile, index: stop_index).value
        node.prev_type_graphid = prev_type_graphid if prev_type_graphid
        prev_type_graphid = node.graphid
        stop_index += 1
        @tile.message.nodes << node
        STOPID_GRAPHID[stop.id] = node.graphid
        GRAPHID_STOPID[node.graphid] = stop.id
      end
    end
  end

  def build_schedule
    puts "Building schedule: #{@tile.tile}"
    stop_ids = @tile.message.nodes.map { |node| GRAPHID_STOPID[node.graphid] }.compact

    # Routes
    routeid_routeindex = {}
    route_index = 0
    route_ids = ScheduleStopPair.where(origin_id: stop_ids).select(:route_id).distinct(:route_id).pluck(:route_id)
    Route.where(id: route_ids).order(id: :asc).includes(:operator).each do |route|
      puts "\troute: #{route.onestop_id}"
      @tile.message.routes << make_route(route, route_index)
      routeid_routeindex[route.id] = route_index
      route_index += 1
    end

    # Shapes
    rspid_rspindex = {}
    rsp_index = 1 # 0 means shape_id is not set in transit builder
    rsp_ids = ScheduleStopPair.where(origin_id: stop_ids).select(:route_stop_pattern_id).distinct(:route_stop_pattern_id).pluck(:route_stop_pattern_id)
    RouteStopPattern.where(id: rsp_ids).order(id: :asc).each do |rsp|
      puts "\trsp: #{rsp.onestop_id}"
      @tile.message.shapes << make_shape(rsp, rsp_index)
      rspid_rspindex[rsp.id] = rsp_index
      rsp_index += 1
    end

    # StopPairs
    ssp_index = 0
    ScheduleStopPair.where(origin_id: stop_ids).includes(:origin, :destination, :operator).find_each do |ssp|
      @tile.message.stop_pairs << make_stop_pair(ssp, routeid_routeindex, rspid_rspindex)
      ssp_index += 1
    end
    puts "\tssp: total #{ssp_index}"
  end

  private

  def make_stop_pair(ssp, routeid_routeindex, rspid_rspindex)
    params = {}
    # bool bikes_allowed = 1;
    # uint32 block_id = 2;
    # uint32 destination_arrival_time = 3;
    params[:destination_arrival_time] = time_to_seconds(ssp.destination_arrival_time)
    # uint64 destination_graphid = 4;
    params[:destination_graphid] = STOPID_GRAPHID[ssp.destination_id]
    # string destination_onestop_id = 5;
    params[:destination_onestop_id] = ssp.destination.onestop_id
    # string operated_by_onestop_id = 6;
    params[:operated_by_onestop_id] = ssp.operator.onestop_id
    # uint32 origin_departure_time = 7;
    params[:origin_departure_time] = time_to_seconds(ssp.origin_departure_time)
    # uint64 origin_graphid = 8;
    params[:origin_graphid] = STOPID_GRAPHID[ssp.origin_id]
    # string origin_onestop_id = 9;
    params[:origin_onestop_id] = ssp.origin.onestop_id
    # uint32 route_index = 10;
    params[:route_index] = routeid_routeindex[ssp.route_id]
    # repeated uint32 service_added_dates = 11;
    params[:service_added_dates] = ssp.service_added_dates.map { |i| date_to_days(i) }
    # repeated bool service_days_of_week = 12;
    params[:service_days_of_week] = ssp.service_days_of_week
    # uint32 service_end_date = 13;
    params[:service_end_date] = date_to_days(ssp.service_end_date)
    # repeated uint32 service_except_dates = 14;
    params[:service_except_dates] = ssp.service_except_dates.map { |i| date_to_days(i) }
    # uint32 service_start_date = 15;
    params[:service_start_date] = date_to_days(ssp.service_start_date)
    # string trip_headsign = 16;
    params[:trip_headsign] = ssp.trip_headsign
    # uint32 trip_id = 17;
    # bool wheelchair_accessible = 18;
    # uint32 shape_id = 20;
    params[:shape_id] = rspid_rspindex[ssp.route_stop_pattern_id]
    # float origin_dist_traveled = 21;
    # params[:origin_dist_traveled] = ssp.origin_dist_traveled,
    # float destination_dist_traveled = 22;
    # params[:destination_dist_traveled] = ssp.destination_dist_traveled
    if ssp.frequency_headway_seconds
      # protobuf doesn't define frequency_start_time
      # uint32 frequency_end_time = 23;
      params[:frequency_end_time] = time_to_seconds(ssp.frequency_end_time)
      # uint32 frequency_headway_seconds = 24;
      params[:frequency_headway_seconds] = ssp.frequency_headway_seconds
    end
    Valhalla::Mjolnir::Transit::StopPair.new(params)
  end

  def make_shape(rsp, rspindex)
    params = {}
    # uint32 shape_id = 1;
    params[:shape_id] = rspindex
    # bytes encoded_shape = 2;
    params[:shape_id] = rsp.id
    Valhalla::Mjolnir::Transit::Shape.new(params.compact)
  end

  def make_route(route, routeindex)
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
    # string route_desc = 7;
    # string route_long_name = 8;
    # uint32 route_text_color = 9;
    # VehicleType vehicle_type = 10;
    Valhalla::Mjolnir::Transit::Route.new(params.compact)
  end

  def make_node(stop)
    params = {}
    # float lon = 1;
    params[:lon] = stop.coordinates[0]
    # float lat = 2;
    params[:lat] = stop.coordinates[1]
    # uint32 type = 3;
    params[:type] = 0
    # uint64 graphid = 4;
    # uint64 prev_type_graphid = 5;
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
      params[:generated] = true
    end
    # uint32 traversability = 12;
    if stop.instance_of?(StopEgress)
      params[:traversability] = 3
    end
    Valhalla::Mjolnir::Transit::Node.new(params.compact)
  end
end

tileset = TileSet.new('.')

puts "Feeds"
build_tiles = Set.new
Feed.where_active_feed_version_import_level(IMPORT_LEVEL).find_each do |feed|
  puts "feed: #{feed.onestop_id}"
  bbox = feed.geometry_bbox
  b = bbox.min_x, bbox.min_y, bbox.max_x, bbox.max_y
  puts "bbox: #{b.join(',')}"
  GraphID.bbox_to_level_tiles(*b).select { |a,b| a == 2}.each { |a,b| build_tiles << tileset.get_tile(a,b) }
end

puts "Tiles to build: #{build_tiles.size}"

builders = build_tiles.map { |tile| TileBuilder.new(tile) }
# Build stops for each tile.
builders.each { |builder| builder.build_stops }
# Build schedule, routes, shapes for each tile.
builders.each { |builder| builder.build_schedule }






#
