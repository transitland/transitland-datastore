describe RGeo::Cartesian do
  context 'with additional LineStringMethods' do
    context 'before?' do
      before(:each) do
        @factory = RGeo::Cartesian::Factory.new
        @line_points = [[-122.401811, 37.706675],[-122.394935, 37.776348]]
        @line = @factory.line_string(@line_points.map {|p| @factory.point(p[0],p[1])})
      end

      it 'checks after?' do
        point = @factory.point(-122.38, 37.8)
        expect(@line.after?(point)).to be true
      end

      it 'checks before?' do
        point = @factory.point(-122.405, 37.63)
        expect(@line.before?(point)).to be true
      end
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
