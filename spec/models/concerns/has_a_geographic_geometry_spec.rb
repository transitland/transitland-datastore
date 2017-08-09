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

  context '.geometry_parse' do
    it 'converts from string' do
      g = Stop.new.geometry_parse('POINT(-122.353165 37.936887)')
      expect(g).to start_with('POINT')
    end

    it 'converts from hash' do
      g = Stop.new.geometry_parse(geometry_point)
      expect(g).to start_with('POINT')
    end
  end

  context '.centroid_from_geometry' do
    it 'works for points' do
      s = create(:stop, geometry: geometry_point)
      centroid = s.centroid_from_geometry(s.read_attribute(:geometry))
      expect(centroid.lat).to be_within(0.001).of(37.78991)
      expect(centroid.lon).to be_within(0.001).of(-122.39327)
    end

    it 'works for polygons' do
      s = create(:stop, geometry: geometry_polygon)
      centroid = s.centroid_from_geometry(s.read_attribute(:geometry))
      expect(centroid.lat).to be_within(0.001).of(37.78989)
      expect(centroid.lon).to be_within(0.001).of(-122.39333)
    end
  end

  context '#geometry' do

  end

  context '#geometry_for_centroid' do
    it 'works for points' do
      s = create(:stop, geometry: geometry_point)
      centroid = s.geometry_centroid
      expect(centroid.lat).to be_within(0.001).of(37.78991)
      expect(centroid.lon).to be_within(0.001).of(-122.39327)
    end

    it 'works for polygons' do
      s = build(:stop, geometry: geometry_polygon)
      centroid = s.geometry_centroid
      expect(centroid.lat).to be_within(0.001).of(37.78989)
      expect(centroid.lon).to be_within(0.001).of(-122.39333)
    end
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
