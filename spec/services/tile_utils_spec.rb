describe TileUtils do
  def assert(b)
    fail Exception.new('test failed') unless b
  end

  context 'GraphID' do
    it 'parses graphid' do
      # GraphID tests
      graphid = TileUtils::GraphID.new(value: 73160266)
      assert graphid.level == 2
      assert graphid.tile == 756425
      assert graphid.bbox == [-73.75, 41.25, -73.5, 41.5]

      graphid = TileUtils::GraphID.new(value: 142438865769)
      assert graphid.level == 1
      assert graphid.tile == 37741
      assert graphid.bbox == [121.0, 14.0, 122.0, 15.0]

      graphid = TileUtils::GraphID.new(level: 0, lat: 14.601879, lon: 120.972545)
      assert graphid.tile == 2415

      graphid = TileUtils::GraphID.new(level: 1, lat: 14.601879, lon: 120.972545)
      assert graphid.tile == 37740

      graphid = TileUtils::GraphID.new(level: 2, lat: 41.413203, lon: -73.623787)
      assert graphid.tile == 756425

      graphid = TileUtils::GraphID.new(value: 73160266)
      assert graphid.tile == 756425

      graphid = TileUtils::GraphID.new(level: 1, tile: 3, index: 7)
      assert graphid.value == 234881049

      graphid = TileUtils::GraphID.new(value: 234881049)
      assert graphid.level == 1
      assert graphid.tile == 3
      assert graphid.index == 7

      level_tiles = TileUtils::GraphID.bbox_to_level_tiles(-74.251961,40.512764,-73.755405,40.903125)
      assert level_tiles.sort == [[2, 752102], [2, 753542], [2, 752103], [2, 753543], [2, 752104], [2, 753544], [1, 46905], [1, 46906], [0, 2906]].sort
    end
  end

  context 'TileSet' do
    it 'test' do
      # TileSet tests
      level = 2
      lon, lat = [-122.29514, 37.804872]

      tiles = TileUtils::TileSet.new('.')

      tile = tiles.get_tile_by_graphid(TileUtils::GraphID.new(level: 2, tile: 736070))
      assert tile.level == 2
      assert tile.tile == 736070

      tile = tiles.get_tile_by_lll(2, lat, lon)
      assert tile.level == 2
      assert tile.tile == 736070
      assert tile.bbox == [-122.5, 37.75, -122.25, 38.0]
    end
  end

  context 'Shape7' do
    it 'test' do
      # Shape7 Tests
      coords = [
        [-74.012666, 40.70136],
        [-74.012962, 40.700478],
        [-74.01265, 40.699074]
      ]
      tolerance = 0.01

      TileUtils::Shape7.decode(TileUtils::Shape7.encode(coords)).zip(coords).each do |a,b|
        assert((a[0]-b[0]).abs < tolerance)
        assert((a[1]-b[1]).abs < tolerance)
      end
    end
  end

  context 'UniqueIndex' do
    it 'test' do
      # UniqueIndex tests
      index = TileUtils::UniqueIndex.new(start: 1)
      assert index.check("foo") == 1
      assert index.check("foo") == 1
      assert index.check("bar") == 2
    end
  end
end
