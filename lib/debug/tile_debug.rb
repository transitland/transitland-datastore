ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Base.logger.level = Logger::DEBUG

tilepath = ARGV[0]
tileid = ARGV[1].to_i

tileset = TileUtils::TileSet.new(tilepath)
tile = tileset.get_tile_by_graphid(TileUtils::GraphID.new(level: 2, tile: tileid))

tile.message.nodes.sort_by(&:onestop_id).each do |node|
  g = TileUtils::GraphID.new(value: node.graphid)
  puts node.to_json
  puts "TILE MISMATCH: node #{g.tile} != tile #{tileid}" if g.tile != tileid
end
