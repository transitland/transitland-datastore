describe HasAGeographicGeometry do
  let (:geometry_point) {
    {
      type: "Point",
      coordinates: [
        -122.39327430725099,
        37.78991914361586
      ]
    }
  }
  let (:geometry_polygon) {
    {
      type: "Polygon",
      coordinates: [
        [
          [
            -122.39363908767702,
            37.78973685348181
          ],
          [
            -122.39363908767702,
            37.79004420286635
          ],
          [
            -122.39303827285767,
            37.79004420286635
          ],
          [
            -122.39303827285767,
            37.78973685348181
          ],
          [
            -122.39363908767702,
            37.78973685348181
          ]
        ]
      ]
    }
  }

  context '.convex_hull' do

  end

  context '.geometry_from_geojson' do
    it 'converts from string' do
      g = HasAGeographicGeometry.geometry_from_geojson(JSON.dump(geometry_point))
      expect(g.geometry_type).to eq(RGeo::Feature::Point)
    end
    it 'converts from hash' do
      g = HasAGeographicGeometry.geometry_from_geojson(geometry_point)
      expect(g.geometry_type).to eq(RGeo::Feature::Point)
    end
  end

  context '#geometry' do

  end

  context '#geometry_centroid' do

  end

  context '#validate' do

  end

  context '#validate_geometry_point' do
    it 'requires point' do
      s = build(:stop, geometry: geometry_point)
      expect(s.send(:validate_geometry_point)).to be true
    end
    it 'returns false otherwise' do
      s = build(:stop, geometry: geometry_polygon)
      expect(s.send(:validate_geometry_point)).to be false
    end
    it 'returns false if nil' do
      s = build(:stop, geometry: nil)
      expect(s.send(:validate_geometry_point)).to be false
    end
  end

  context '#validate_geometry_polygon' do
    it 'requires polygon' do
      s = build(:stop, geometry: geometry_polygon)
      expect(s.send(:validate_geometry_polygon)).to be true
    end
    it 'returns false otherwise' do
      s = build(:stop, geometry: geometry_point)
      expect(s.send(:validate_geometry_polygon)).to be false
    end
    it 'returns false if nil' do
      s = build(:stop, geometry: nil)
      expect(s.send(:validate_geometry_polygon)).to be false
    end
  end

end
