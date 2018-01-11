ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Base.logger.level = Logger::DEBUG

tilepath = ARGV[0]
tileid = ARGV[1].to_i

tileset = TileUtils::TileSet.new(tilepath)
tile = tileset.get_tile_by_graphid(TileUtils::GraphID.new(level: 2, tile: tileid))

puts "Tile #{tileid}"
puts "\tnodes: #{tile.message.nodes.size}"
puts "\troutes: #{tile.message.routes.size}"
puts "\tshapes: #{tile.message.shapes.size}"
puts "\tstop_pairs: #{tile.message.stop_pairs.size}"
puts "\n"

tile.message.nodes.sort_by(&:onestop_id).each do |node|
  g = TileUtils::GraphID.new(value: node.graphid)
  puts "node index #{g.index}: #{node.to_json}"
  puts "TILE MISMATCH: node #{g.tile} != tile #{tileid}" if g.tile != tileid
end

tile.message.routes.sort_by(&:onestop_id).each do |route|
  puts route.to_json
end

tile.message.shapes
  .map { |shape| [shape.shape_id, TileUtils::Shape7.decode(shape.encoded_shape)] }
  .sort_by { |shape_id, coords| [coords.first[0], coords.first[1], coords.last[0], coords.last[1]] }
  .each do |shape_id, coords|
    puts "shape_id: #{shape_id} coords first: #{coords.first} last: #{coords.last}"
end

tile.message.stop_pairs.sort_by { |stop_pair| [stop_pair.origin_graphid, stop_pair.origin_departure_time, stop_pair.origin_dist_traveled, stop_pair.service_added_dates, stop_pair.service_days_of_week] }.each do |stop_pair|
  puts "origin: #{stop_pair.origin_graphid} destination: #{stop_pair.destination_graphid}"
  j = stop_pair.as_json
  # remove keys likely to differ, but only need to be internally consistent
  j.delete(:shape_id)
  j.delete(:trip_id)
  j.delete(:operated_by_onestop_id)
  j.sort_by { |k,v| k }.each { |k,v| puts "\t#{k}: #{v.inspect}"}
end






#
