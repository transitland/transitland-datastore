describe RGeo::Cartesian do
  context 'with additional LineStringMethods' do
    before(:each) do
      @factory = RGeo::Cartesian::Factory.new
      line_points = [[-121.0, 36.0],[-121.0, 34.0],[-122.0, 33.0]]
      @line = @factory.line_string(line_points.map {|p| @factory.point(p[0],p[1])})
    end

    it 'calculates distance_from_departure_to_segment' do
      expect(@line.distance_from_departure_to_segment(@line._segments[-1])).to eq(2.0)
    end

    it 'splits a line at a point' do
      target = @factory.point(-121.0, 34.0)
      splits = @line.split_at_point(target)
      @split_line1 = @factory.line_string([[-121.0, 36.0], [-121.0, 34.0]].map {|p| @factory.point(p[0],p[1])})
      @split_line2 = @factory.line_string([[-121.0, 34.0], [-122.0, 33.0]].map {|p| @factory.point(p[0],p[1])})
      expect(splits[0]).to eq(@split_line1)
      expect(splits[1]).to eq(@split_line2)

      target = @factory.point(-121.0, 35.0)
      splits = @line.split_at_point(target)
      @split_line1 = @factory.line_string([[-121.0, 36.0], [-121.0, 35.0]].map {|p| @factory.point(p[0],p[1])})
      @split_line2 = @factory.line_string([[-121.0, 35.0], [-121.0, 34.0], [-122.0, 33.0]].map {|p| @factory.point(p[0],p[1])})
      expect(splits[0]).to eq(@split_line1)
      expect(splits[1]).to eq(@split_line2)

      target = @factory.point(-121.0, 37.0)
      splits = @line.split_at_point(target)
      expect(splits[0]).to eq(nil)
      expect(splits[1]).to eq(@line)

      target = @factory.point(-121.0, 32.0)
      splits = @line.split_at_point(target)
      expect(splits[0]).to eq(@line)
      expect(splits[1]).to eq(nil)
    end
  end

  context 'with PointLocator' do
    before(:each) do
      @factory = RGeo::Cartesian::Factory.new
      line_points = [[-121.0, 36.0],[-121.0, 34.0]]
      @line = @factory.line_string(line_points.map {|p| @factory.point(p[0],p[1])})
    end
    it 'calculates distance_on_segment' do
      point = @factory.point(-121.0, 35.0)
      locator = RGeo::Cartesian::PointLocator.new(point, @line._segments[0])
      expect(locator.distance_on_segment).to be_within(0.000001).of(1.0)

      point = @factory.point(-121.0, 36.0)
      locator = RGeo::Cartesian::PointLocator.new(point, @line._segments[0])
      expect(locator.distance_on_segment).to be_within(0.000001).of(0.0)
    end

    it 'calculates distance_from_segment' do
      point = @factory.point(-122.0, 35.0)
      locator = RGeo::Cartesian::PointLocator.new(point, @line._segments[0])
      expect(locator.distance_from_segment).to be_within(0.000001).of(1.0)

      point = @factory.point(-121.0, 35.0)
      locator = RGeo::Cartesian::PointLocator.new(point, @line._segments[0])
      expect(locator.distance_from_segment).to be_within(0.000001).of(0.0)

      point = @factory.point(-121.0, 37.0)
      locator = RGeo::Cartesian::PointLocator.new(point, @line._segments[0])
      expect(locator.distance_from_segment).to be_within(0.000001).of(1.0)
    end

    it 'calculates target_distance_from_departure' do
      point = @factory.point(-122.0, 34.0)
      locator = RGeo::Cartesian::PointLocator.new(point, @line._segments[0])
      expect(locator.target_distance_from_departure).to be_within(0.000001).of(2.236067977)
    end

    it 'interpolates point' do
      point = @factory.point(-122.0, 35.0)
      locator = RGeo::Cartesian::PointLocator.new(point, @line._segments[0])
      expect(locator.interpolate_point(@factory)).to eq(@factory.point(-121.0, 35.0))

      point = @factory.point(-122.0, 37.0)
      locator = RGeo::Cartesian::PointLocator.new(point, @line._segments[0])
      expect(locator.interpolate_point(@factory)).to eq(@factory.point(-121.0, 36.0))

      point = @factory.point(-122.0, 33.0)
      locator = RGeo::Cartesian::PointLocator.new(point, @line._segments[0])
      expect(locator.interpolate_point(@factory)).to eq(@factory.point(-121.0, 34.0))
    end
  end
end
