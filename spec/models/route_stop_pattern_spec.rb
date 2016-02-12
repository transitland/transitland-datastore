# == Schema Information
#
# Table name: current_route_stop_patterns
#
#  id                                 :integer          not null, primary key
#  onestop_id                         :string
#  geometry                           :geography({:srid geometry, 4326
#  tags                               :hstore
#  stop_pattern                       :string           default([]), is an Array
#  version                            :integer
#  is_generated                       :boolean          default(FALSE)
#  is_modified                        :boolean          default(FALSE)
#  trips                              :string           default([]), is an Array
#  identifiers                        :string           default([]), is an Array
#  created_at                         :datetime         not null
#  updated_at                         :datetime         not null
#  created_or_updated_in_changeset_id :integer
#  route_id                           :integer
#
# Indexes
#
#  c_rsp_cu_in_changeset                              (created_or_updated_in_changeset_id)
#  index_current_route_stop_patterns_on_identifiers   (identifiers)
#  index_current_route_stop_patterns_on_onestop_id    (onestop_id)
#  index_current_route_stop_patterns_on_route_id      (route_id)
#  index_current_route_stop_patterns_on_stop_pattern  (stop_pattern)
#  index_current_route_stop_patterns_on_trips         (trips)
#

describe RouteStopPattern do
  let(:stop_1) { create(:stop,
    onestop_id: "s-9q8yw8y448-bayshorecaltrainstation",
    geometry: Stop::GEOFACTORY.point(-122.401811, 37.706675).to_s
  )}
  let(:stop_2) { create(:stop,
    onestop_id: "s-9q8yyugptw-sanfranciscocaltrainstation",
    geometry: Stop::GEOFACTORY.point(-122.394935, 37.776348).to_s
  )}
  let(:stop_a) { create(:stop,
    onestop_id: "s-9q9k659e3r-sanjosecaltrainstation",
    geometry: Stop::GEOFACTORY.point(-121.902181, 37.329392).to_s
  )}
  let(:stop_b) { create(:stop,
    onestop_id: "s-9q9hxhecje-sunnyvalecaltrainstation",
    geometry: Stop::GEOFACTORY.point(-122.030742, 37.378427).to_s
  )}
  let(:stop_c) { create(:stop,
    onestop_id: "s-9q9hwp6epk-mountainviewcaltrainstation",
    geometry: Stop::GEOFACTORY.point(-122.076327, 37.393879).to_s
  )}
  let(:route_onestop_id) { 'r-9q9j-bullet' }

  before(:each) do
    @geom_points = [[-122.401811, 37.706675],[-122.394935, 37.776348]]
    @geom = RouteStopPattern::GEOFACTORY.line_string(
      @geom_points.map {|lon, lat| RouteStopPattern::GEOFACTORY.point(lon, lat)}
    )
    @sp = [stop_1.onestop_id, stop_2.onestop_id]
    @onestop_id = OnestopId::RouteStopPatternOnestopId.new(route_onestop_id: route_onestop_id,
                                                           stop_pattern: @sp,
                                                           geometry_coords: @geom.coordinates).to_s
    @rsp = RouteStopPattern.new(
     stop_pattern: @sp,
     geometry: @geom
    )
  end

  context 'creation' do

    it 'can be created' do
      rsp = create(:route_stop_pattern, stop_pattern: @sp, geometry: @geom, onestop_id: @onestop_id)
      expect(RouteStopPattern.exists?(rsp.id)).to be true
      expect(RouteStopPattern.find(rsp.id).stop_pattern).to match_array(@sp)
      expect(RouteStopPattern.find(rsp.id).geometry[:coordinates]).to eq @geom.points.map{|p| [p.x,p.y]}
    end

    it 'cannot be created when stop_pattern has less than two stops' do
      sp = [stop_1.onestop_id]
      rsp = expect(build(:route_stop_pattern, stop_pattern: sp, geometry: @geom, onestop_id: @onestop_id)
        .valid?
      ).to be false
    end

    it 'cannot be created when geometry has less than two points' do
      rsp = build(:route_stop_pattern,
            stop_pattern: @sp,
            geometry: @geom,
            onestop_id: @onestop_id
      )
      points = [[-122.401811, 37.706675]]
      geom = RouteStopPattern::GEOFACTORY.line_string(
        points.map {|lon, lat| RouteStopPattern::GEOFACTORY.point(lon, lat)}
      )
      rsp.geometry = geom
      rsp = expect(rsp.valid?).to be false
    end
  end

  it 'can create new geometry' do
    expect(RouteStopPattern.line_string([[1,2],[2,2]]).is_a?(RGeo::Geographic::SphericalLineStringImpl)).to be true
  end

  it 'can simplify line geometry' do
    expect(RouteStopPattern.simplify_geometry([[-122.0123456,45.01234567],
                                               [-122.0123478,45.01234589],
                                               [-123.0,45.0]])).to match_array([[-122.01235,45.01235],[-123.0,45.0]])
  end

  context 'new import' do
    before(:each) do
      @route = create(:route, onestop_id: route_onestop_id)
      @saved_rsp = create(:route_stop_pattern, stop_pattern: @sp, geometry: @geom, onestop_id: @onestop_id, route: @route)
      import_sp = [ stop_a.onestop_id, stop_b.onestop_id, stop_c.onestop_id ]
      import_geometry = RouteStopPattern.line_string([stop_a.geometry[:coordinates],
                                                      stop_b.geometry[:coordinates],
                                                      stop_c.geometry[:coordinates]])
      import_onestop_id = OnestopId::RouteStopPatternOnestopId.new(route_onestop_id: route_onestop_id,
                                                                  stop_pattern: import_sp,
                                                                  geometry_coords: import_geometry.coordinates).to_s
      @import_rsp = RouteStopPattern.new(
        onestop_id: import_onestop_id,
        stop_pattern: import_sp,
        geometry: import_geometry,
        route: @route
      )
    end
  end

  it 'can be found by stops' do
    rsp = create(:route_stop_pattern, stop_pattern: @sp, geometry: @geom, onestop_id: @onestop_id)
    expect(RouteStopPattern.with_stops('s-9q8yw8y448-bayshorecaltrainstation')).to match_array([rsp])
    expect(RouteStopPattern.with_stops('s-9q8yw8y448-bayshorecaltrainstation,s-9q8yyugptw-sanfranciscocaltrainstation')).to match_array([rsp])
    expect(RouteStopPattern.with_stops('s-9q9k659e3r-sanjosecaltrainstation')).to match_array([])
    expect(RouteStopPattern.with_stops('s-9q8yw8y448-bayshorecaltrainstation,s-9q9k659e3r-sanjosecaltrainstation')).to match_array([])
  end

  it 'can be found by trips' do
    rsp = create(:route_stop_pattern, stop_pattern: @sp, geometry: @geom, onestop_id: @onestop_id, trips: ['trip1','trip2'])
    expect(RouteStopPattern.with_trips('trip1')).to match_array([rsp])
    expect(RouteStopPattern.with_trips('trip1,trip2')).to match_array([rsp])
    expect(RouteStopPattern.with_trips('trip3')).to match_array([])
    expect(RouteStopPattern.with_trips('trip1,trip3')).to match_array([])
  end

  context 'calculate_distances' do
    before(:each) do
      @sp = [stop_a.onestop_id,
             stop_b.onestop_id,
             stop_c.onestop_id]
      @geom = RouteStopPattern.line_string([stop_a.geometry[:coordinates],
                                            stop_b.geometry[:coordinates],
                                            stop_c.geometry[:coordinates]])
      @rsp = RouteStopPattern.new(
        stop_pattern: @sp,
        geometry: @geom
      )
      @rsp.route = Route.new(onestop_id: route_onestop_id)
      @rsp.onestop_id = OnestopId::RouteStopPatternOnestopId.new(route_onestop_id: route_onestop_id,
                                                             stop_pattern: @sp,
                                                             geometry_coords: @geom.coordinates).to_s
      @trip = GTFS::Trip.new(trip_id: 'test', shape_id: 'test')
    end

    it 'can calculate distances when the geometry and stop coordinates are equal' do
      expect(@rsp.calculate_distances).to match_array([a_value_within(0.1).of(0.0),
                                                              a_value_within(0.1).of(12617.9271),
                                                              a_value_within(0.1).of(17001.5107)])
    end

    it 'can calculate distances when a stop is on a segment between two geometry coordinates' do
      mv_syvalue_midpoint = [(@rsp.geometry[:coordinates][2][0] + @rsp.geometry[:coordinates][1][0])/2.0,
                             (@rsp.geometry[:coordinates][2][1] + @rsp.geometry[:coordinates][1][1])/2.0]
      midpoint = create(:stop,
        onestop_id: "s-9q9hwtgq4s-midpoint",
        geometry: Stop::GEOFACTORY.point(mv_syvalue_midpoint[0], mv_syvalue_midpoint[1]).to_s
      )
      @rsp.stop_pattern = [stop_a.onestop_id,
                           stop_b.onestop_id,
                           midpoint.onestop_id,
                           stop_c.onestop_id]
      expect(@rsp.calculate_distances).to match_array([a_value_within(0.1).of(0.0),
                                                              a_value_within(0.1).of(12617.9271),
                                                              a_value_within(0.1).of(14809.7189),
                                                              a_value_within(0.1).of(17001.5107)])
    end

    it 'can calculate distances when a stop is between two geometry coordinates but not on a segment' do
      p_offset = create(:stop,
       onestop_id: "s-9q9hwtgq4s-midpoint~perpendicular~offset",
       geometry: Stop::GEOFACTORY.point(-122.0519858, 37.39072182536).to_s
      )
      @rsp.stop_pattern = [stop_a.onestop_id,
                           stop_b.onestop_id,
                           p_offset.onestop_id,
                           stop_c.onestop_id]
      expect(@rsp.calculate_distances).to match_array([a_value_within(0.1).of(0.0),
                                                              a_value_within(0.1).of(12617.9271),
                                                              a_value_within(0.5).of(14809.7189),
                                                              a_value_within(0.1).of(17001.5107)])
    end

    it 'can calculate distances by matching stops to the right segments if considered sequentially' do
      a = create(:stop,
        onestop_id: "s-dqcjq9vgbv-A",
        geometry: Stop::GEOFACTORY.point(-77.050171, 38.901890).to_s
      )
      b = create(:stop,
        onestop_id: "s-dqcjq9vc13-B",
        geometry: Stop::GEOFACTORY.point(-77.050155, 38.901394).to_s
      )
      @loop_rsp = RouteStopPattern.new(stop_pattern: [a.onestop_id, b.onestop_id], geometry: RouteStopPattern.line_string(
        [[-77.050176, 38.900751],
        [-77.050187, 38.901394],
        [-77.050187, 38.901920],
        [-77.050702, 38.902195],
        [-77.050777, 38.902638],
        [-77.050401, 38.903005],
        [-77.049961, 38.903034],
        [-77.049634, 38.902901],
        [-77.049473, 38.902638],
        [-77.049527, 38.902312],
        [-77.049725, 38.902078],
        [-77.050069, 38.901978],
        [-77.050074, 38.901389],
        [-77.050048, 38.900776]]
      ))
      expect(@loop_rsp.calculate_distances).to match_array(
        [a_value_within(0.1).of(126.80),
         a_value_within(0.1).of(553.56)]
      )
    end

    it 'can calculate distances when a stop is before the first point of a geometry' do
      @rsp.stop_pattern = @rsp.stop_pattern.unshift(create(:stop,
        onestop_id: "s-9q9hwp6epk-before~geometry",
        geometry: Stop::GEOFACTORY.point(-121.5, 37.30).to_s
      ).onestop_id)
      stop_points = @rsp.geometry[:coordinates].unshift([-121.5, 37.30])
      has_issues, issues = @rsp.evaluate_geometry(@trip, stop_points)
      @rsp.tl_geometry(stop_points, issues)
      expect(@rsp.calculate_distances).to match_array([a_value_within(0.1).of(0.0),
                                                       a_value_within(0.1).of(35756.8357),
                                                       a_value_within(0.1).of(48374.7628),
                                                       a_value_within(0.1).of(52758.3464)])
    end

    it 'can calculate distances when a stop is after the last point of a geometry' do
      @rsp.stop_pattern << create(:stop,
       onestop_id: "s-9q9hwp6epk-after~geometry",
       geometry: Stop::GEOFACTORY.point(-122.1, 37.41).to_s
      ).onestop_id
      stop_points = @rsp.geometry[:coordinates] << [-122.1, 37.41]
      has_issues, issues = @rsp.evaluate_geometry(@trip, stop_points)
      @rsp.tl_geometry(stop_points, issues)
      expect(@rsp.calculate_distances).to match_array([a_value_within(0.1).of(0.0),
                                                       a_value_within(0.1).of(12617.9271),
                                                       a_value_within(0.1).of(17001.5107),
                                                       a_value_within(0.1).of(19758.8669)])
    end

    it 'can continue distance calculation when a stop is an outlier' do
      outlier = create(:stop,
        onestop_id: "s-9q9hwtgq4s-outlier",
        geometry: Stop::GEOFACTORY.point(-63.0, 30.0).to_s
      )
      @rsp.stop_pattern = [stop_a.onestop_id,
                           stop_b.onestop_id,
                           outlier.onestop_id,
                           stop_c.onestop_id]
      expect(@rsp.calculate_distances).to match_array([a_value_within(0.1).of(0.0),
                                                              a_value_within(0.1).of(12617.9271),
                                                              a_value_within(0.1).of(12617.9271),
                                                              a_value_within(0.1).of(17001.5107)])
    end

    it 'can calculate distances when two consecutive stop points are identical' do
      identical = create(:stop,
        onestop_id: "s-9q9hwtgq4s-sunnyvaleidentical",
        geometry: stop_2.geometry
      )
      @rsp.stop_pattern = [stop_a.onestop_id,
                           stop_b.onestop_id,
                           identical.onestop_id,
                           stop_c.onestop_id]
      expect(@rsp.calculate_distances).to match_array([a_value_within(0.1).of(0.0),
                                                              a_value_within(0.1).of(12617.9271),
                                                              a_value_within(0.1).of(12617.9271),
                                                              a_value_within(0.1).of(17001.5107)])
    end
  end

  context 'determining outlier stops' do
    it 'returns false when the stop is within 100 meters of the closest point on the line' do
      # distance is approx 81 m
      test_stop = create(:stop,
        onestop_id: "s-9q8yw8y448-test",
        geometry: Stop::GEOFACTORY.point(-122.3975, 37.741).to_s
      )
      @rsp.stop_pattern = [@sp[0],test_stop.onestop_id,@sp[1]]
      expect(@rsp.outlier_stop(test_stop[:geometry])).to be false
    end

    it 'returns true when the stop is greater than 100 meters of the closest point on the line' do
      # distance is approx 146 m
      test_stop = create(:stop,
        onestop_id: "s-9q8yw8y448-test",
        geometry: Stop::GEOFACTORY.point(-122.3968, 37.7405).to_s
      )
      @rsp.stop_pattern = [@sp[0],test_stop.onestop_id,@sp[1]]
      expect(@rsp.outlier_stop(test_stop[:geometry])).to be true
    end
  end

  context 'before and after stops' do
    before(:each) do
      @trip = GTFS::Trip.new(trip_id: 'test')
    end

    it 'is marked correctly as having an after stop after evaluation' do
      stop_points = @geom_points << [-122.38, 37.8]
      @trip.shape_id = 'test_shape'
      has_issues, issues = @rsp.evaluate_geometry(@trip, stop_points)
      expect(has_issues).to be true
      expect(issues).to match_array([:has_after_stop])
    end

    it 'does not have an after stop if the last stop is close to the line and below the last stop perpendicular' do
      stop_points = @geom_points << [-122.3975, 37.741]
      @trip.shape_id = 'test_shape'
      has_issues, issues = @rsp.evaluate_geometry(@trip, stop_points)
      expect(has_issues).to be false
      expect(issues).to match_array([])
    end

    it 'has an after stop if the last stop is below the last stop perpendicular but not close enough to the line' do
      stop_points = @geom_points << [-122.39, 37.77]
      @trip.shape_id = 'test_shape'
      has_issues, issues = @rsp.evaluate_geometry(@trip, stop_points)
      expect(has_issues).to be true
      expect(issues).to match_array([:has_after_stop])
    end

    it 'is marked correctly as having a before stop after evaluation' do
      stop_points = @geom_points.unshift([-122.405, 37.63])
      @trip.shape_id = 'test_shape'
      has_issues, issues = @rsp.evaluate_geometry(@trip, stop_points)
      expect(has_issues).to be true
      expect(issues).to match_array([:has_before_stop])
    end

    it 'does not have a before stop if the first stop is close to the line and above the first stop perpendicular' do
      stop_points = @geom_points.unshift([-122.40182, 37.7067])
      @trip.shape_id = 'test_shape'
      has_issues, issues = @rsp.evaluate_geometry(@trip, stop_points)
      expect(has_issues).to be false
      expect(issues).to match_array([])
    end

    it 'has a before stop if the first stop is above the first stop perpendicular but not close enough to the line' do
      stop_points = @geom_points.unshift([-122.40182, 37.72])
      @trip.shape_id = 'test_shape'
      has_issues, issues = @rsp.evaluate_geometry(@trip, stop_points)
      expect(has_issues).to be true
      expect(issues).to match_array([:has_before_stop])
    end
  end

  context 'without shape or shape points' do
    before(:each) do
      @trip = GTFS::Trip.new(trip_id: 'test')
      @empty_rsp = RouteStopPattern.new(stop_pattern: [], geometry: RouteStopPattern.line_string([]))
    end

    it 'is marked as empty after evaluation' do
      has_issues, issues = @empty_rsp.evaluate_geometry(@trip, [])
      expect(has_issues).to be true
      expect(issues).to match_array([:empty])

      has_issues, issues = @rsp.evaluate_geometry(@trip, [])
      expect(has_issues).to be true
      expect(issues).to match_array([:empty])

      @trip.shape_id = 'test_shape'
      has_issues, issues = @empty_rsp.evaluate_geometry(@trip, [])
      expect(has_issues).to be true
      expect(issues).to match_array([:empty])
    end

    it 'adds geometry consisting of stop points' do
      issues = [:empty]
      stop_points = @geom_points
      @empty_rsp.tl_geometry(stop_points, issues)
      expect(@empty_rsp.geometry[:coordinates]).to eq(stop_points)
      expect(@empty_rsp.is_generated).to be true
      expect(@empty_rsp.is_modified).to be true
    end
  end
end
