require 'fileutils'
require 'google/protobuf'
load 'lib/proto/transit_pb.rb'

class Tile
  attr_accessor :level, :tile, :message
  def initialize(level, tile, data: nil)
    @level = level
    @tile = tile
    if data
      @message = Valhalla::Mjolnir::Transit.decode(data)
    else
      @message = Valhalla::Mjolnir::Transit.new
    end
  end

  def encode
    Valhalla::Mjolnir::Transit.encode(@message)
  end
end

class TileSet
  def initialize(path)
    @path = path
    @tiles = {}
  end

  def get_tile(level, tile)
    @tiles[[level, tile]] ||= read_tile(level, tile)
  end

  def get_tile_by_lll(level, lat, lon)
    get_tile_by_graphid(GraphID.new(level: level, lat: lat, lon: lon))
  end

  def get_tile_by_graphid(graphid)
    get_tile(graphid.level, graphid.tile)
  end

  def write_tile(tile)
    fn = tile_path(tile.level, tile.tile)
    FileUtils.mkdir_p(File.dirname(fn))
    File.open(fn, 'wb') do |f|
      f.write(tile.encode)
    end
  end

  private

  def tile_path(level, tile)
    s = tile.to_s.rjust(9, "0")
    File.join(@path, level.to_s, s[0...3], s[3...6], s[6...9]+".pbf")
  end

  def read_tile(level, tile)
    fn = tile_path(level, tile)
    if File.exists?(fn)
      Tile.new(level, tile, data: File.read(fn))
    else
      Tile.new(level, tile)
    end
  end

end

class GraphID
  SIZES = [4.0, 1.0, 0.25]
  LEVEL_BITS = 3
  TILE_INDEX_BITS = 22
  ID_INDEX_BITS = 21
  LEVEL_MASK = (2**LEVEL_BITS) - 1
  TILE_INDEX_MASK = (2**TILE_INDEX_BITS) - 1
  ID_INDEX_MASK = (2**ID_INDEX_BITS) - 1
  INVALID_ID = (ID_INDEX_MASK << (TILE_INDEX_BITS + LEVEL_BITS)) | (TILE_INDEX_MASK << LEVEL_BITS) | LEVEL_MASK

  attr_accessor :value
  def initialize(value: nil, **kwargs)
    @value = value || (self.class.make_id(**kwargs))
  end

  def self.make_id(level: 0, tile: 0, index: 0, lat: nil, lon: nil)
    if lat && lon
      tile = lll_to_tile(level, lat, lon)
    end
    level | tile << LEVEL_BITS | index << (LEVEL_BITS + TILE_INDEX_BITS)
  end

  def self.lll_to_tile(tile_level, lat, lon)
    size = SIZES[tile_level]
    width = (360 / size).to_i
    ((lat + 90) / size).to_i * width + ((lon + 180 ) / size).to_i
  end

  def get_ll
    size = SIZES[level]
    width = (360 / size).to_i
    height = (180 / size).to_i
    [(tile / width).to_i * size - 90, (tile % width) * size - 180]
  end

  def level
    @value & LEVEL_MASK
  end

  def tile
    (@value >> LEVEL_BITS )& TILE_INDEX_MASK
  end

  def index
    (@value >> LEVEL_BITS + TILE_INDEX_BITS) & ID_INDEX_MASK
  end
end
