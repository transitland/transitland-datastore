load 'lib/proto/tile_set.rb'

EPOCH = Date.parse('1970-01-01')
IMPORT_LEVEL = 4
LEVEL = 2
STOPID_GRAPHID = {}

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

  def build
    puts "Building tile: #{@tile.tile}"
    add_stops
    add_stop_pairs
    add_routes
    add_shapes
  end

  private

  def add_stops
    Stop.where(parent_stop: nil).geometry_within_bbox(@tile.bbox).each do |stop|
      next if STOPID_GRAPHID[stop.id]
      node = make_stop(stop)
      STOPID_GRAPHID[stop.id] = node.graphid
      @tile.message.nodes << node
    end
  end

  def make_stop(stop)
    graphid = GraphID.new(level: LEVEL, tile: @tile.tile, index: @tile.next_index)
    fail Exception.new('stop not in this tile!') if graphid.tile != @tile.tile
    params = {}
    # float lon = 1;
    params[:lon] = stop.coordinates[1]
    # float lat = 2;
    params[:lat] = stop.coordinates[0]
    # uint32 type = 3;
    # uint64 graphid = 4;
    params[:graphid] = graphid.value
    # uint64 prev_type_graphid = 5;
    # string name = 6;
    params[:name] = stop.name
    # string onestop_id = 7;
    params[:onestop_id] = stop.onestop_id
    # uint64 osm_way_id = 8;
    # string timezone = 9;
    # bool wheelchair_boarding = 10;
    # bool generated = 11;
    # uint32 traversability = 12;
    Valhalla::Mjolnir::Transit::Node.new(params)
  end

  def add_routes
  end

  def add_stop_pairs
  end

  def add_shapes
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

build_tiles.each do |tile|
  builder = TileBuilder.new(tile)
  builder.build
end

puts STOPID_GRAPHID
puts STOPID_GRAPHID.size

# ScheduleStopPair.where('').includes{[origin, destination, route, route_stop_pattern, operator]}.limit(1).each do |ssp|
#   params = {
#     # optional :bikes_allowed, :bool, 1
#     # bikes_allowed: ssp.bikes_allowed,
#     # optional :destination_arrival_time, :uint32, 3
#     destination_arrival_time: time_to_seconds(ssp.destination_arrival_time),
#     # optional :destination_graphid, :uint64, 4
#     destination_graphid: stop_graphid[ssp.destination.id],
#     # optional :destination_onestop_id, :string, 5
#     destination_onestop_id: ssp.destination.onestop_id,
#     # optional :operated_by_onestop_id, :string, 6
#     operated_by_onestop_id: ssp.operator.onestop_id,
#     # optional :origin_departure_time, :uint32, 7
#     origin_departure_time: time_to_seconds(ssp.origin_departure_time),
#     # optional :origin_graphid, :uint64, 8
#     origin_graphid: stop_graphid[ssp.origin.id],
#     # optional :origin_onestop_id, :string, 9
#     origin_onestop_id: ssp.origin.onestop_id,
#     # optional :route_index, :uint32, 10
#     # route_index: '???',
#     # repeated :service_added_dates, :uint32, 11
#     service_added_dates: ssp.service_added_dates.map { |i| date_to_days(i) },
#     # repeated :service_days_of_week, :bool, 12
#     service_days_of_week: ssp.service_days_of_week,
#     # optional :service_end_date, :uint32, 13
#     service_end_date: date_to_days(ssp.service_end_date),
#     # repeated :service_except_dates, :uint32, 14
#     service_except_dates: ssp.service_except_dates.map { |i| date_to_days(i) },
#     # optional :service_start_date, :uint32, 15
#     service_start_date: date_to_days(ssp.service_start_date),
#     # optional :trip_headsign, :string, 16
#     trip_headsign: ssp.trip_headsign,
#     # optional :trip_id, :uint32, 17
#     # trip_id: ssp.trip,
#     # optional :wheelchair_accessible, :bool, 18
#     wheelchair_accessible: ssp.wheelchair_accessible,
#     # optional :shape_id, :uint32, 20
#     # shape_id: '???',
#     # optional :origin_dist_traveled, :float, 21
#     origin_dist_traveled: ssp.origin_dist_traveled,
#     # optional :destination_dist_traveled, :float, 22
#     destination_dist_traveled: ssp.destination_dist_traveled,
#   }
#   # optional :block_id, :uint32, 2
#   params[:block_id] = ssp.block_id.to_i if ssp.block_id
#   # Frequency
#   if ssp.frequency_headway_seconds
#     # optional :frequency_headway_seconds, :uint32, 24
#     params[:frequency_headway_seconds] = ssp.frequency_headway_seconds
#     # optional :frequency_end_time, :uint32, 23
#     params[:frequency_end_time] = time_to_seconds(ssp.frequency_end_time)
#     # protobuf doesn't define frequency_start_time
#     # params[:frequency_start_time] = time_to_seconds(ssp.frequency_start_time)
#   end
#   tile.stop_pairs << Valhalla::Mjolnir::Transit_Fetch::StopPair.new(**params)
# end
#
# Route.where('').include{[operator]}.limit(1).each do |route|
#   params = {
#     # optional :name, :string, 1
#     name: route.name,
#     # optional :onestop_id, :string, 2
#     onestop_id: route.onestop_id,
#     # optional :operated_by_name, :string, 3
#     operated_by_name: route.operator.name,
#     # optional :operated_by_onestop_id, :string, 4
#     operated_by_onestop_id: route.operator.onestop_id,
#     # optional :route_desc, :string, 7
#     # route_desc: route.desc,
#     # optional :route_long_name, :string, 8
#     # route_long_name: route.route_long_name,
#     # optional :route_text_color, :uint32, 9
#     # route_text_color: route.text_color,
#     # optional :vehicle_type, :enum, 10, "valhalla.mjolnir.Transit_Fetch.VehicleType"
#   }
#   # optional :route_color, :uint32, 6
#   params[:route_color] = color_to_int(route.color) if route.color
#   # optional :operated_by_website, :string, 5
#   params[:operated_by_website] = route.operator.website if route.operator.website
#   tile.routes << Valhalla::Mjolnir::Transit_Fetch::Route.new(**params)
# end
#
