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

  it '#simplify_geometry' do
    expect(RouteStopPattern.simplify_geometry([[-122.0123456,45.01234567],
                                               [-122.0123478,45.01234589],
                                               [-123.0,45.0]])).to match_array([[-122.01235,45.01235],[-123.0,45.0]])
  end

  it '#set_precision' do
    expect(RouteStopPattern.set_precision([[-122.0123456,45.01234567],
                                           [-122.9123478,45.91234589]])).to match_array([[-122.01235,45.01235],[-122.91235,45.91235]])
  end

  it '#remove_duplicate_points' do
    expect(RouteStopPattern.remove_duplicate_points([[-122.0123,45.0123],
                                                     [-122.0123,45.0123],
                                                     [-122.9876,45.9876],
                                                     [-122.0123,45.0123]])).to match_array([[-122.0123,45.0123],[-122.9876,45.9876],[-122.0123,45.0123]])
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
       geometry: Stop::GEOFACTORY.point(-122.053340913, 37.3867241032).to_s
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

    it 'can accurately calculate distances when a stop is repeated' do
      # from vta
      first_stop = create(:stop,
        onestop_id: "s-9q9kf43sce-main~abel",
        geometry: Stop::GEOFACTORY.point(-121.9021635, 37.4106536).to_s
      )
      second_stop = create(:stop,
        onestop_id: "s-9q9kf51txf-main~greatmallparkway",
        geometry: Stop::GEOFACTORY.point(-121.9019025, 37.41489919).to_s
      )
      third_stop = create(:stop,
        onestop_id: "s-9q9kf4gkqz-greatmall~maintransitcenter",
        geometry: Stop::GEOFACTORY.point(-121.8995438, 37.41333833).to_s
      )
      fourth_stop = create(:stop,
        onestop_id: "s-9q9kf51txf-main~greatmallparkway",
        geometry: Stop::GEOFACTORY.point(-121.9019025, 37.41489919).to_s
      )
      fifth_stop = create(:stop,
        onestop_id: "s-9q9kf5bqpy-main~curtisfs",
        geometry: Stop::GEOFACTORY.point(-121.903617, 37.41912585).to_s
      )

      @repeated_rsp = RouteStopPattern.new(
        stop_pattern: [first_stop.onestop_id,
                       second_stop.onestop_id,
                       third_stop.onestop_id,
                       fourth_stop.onestop_id,
                       fifth_stop.onestop_id],
        geometry: RouteStopPattern.line_string(
          [[-121.902442,37.409873],
          [-121.902364,37.41048],
          [-121.902276,37.410613],
          [-121.902255,37.411024],
          [-121.902233,37.411126],
          [-121.902182,37.411215],
          [-121.902105,37.41129],
          [ -121.902045,37.411327],
          [-121.902015,37.411378],
          [-121.901963,37.411617],
          [-121.9018,37.412433],
          [-121.901654,37.413186],
          [-121.901646,37.413442],
          [-121.901676,37.41367],
          [-121.901723,37.413893],
          [-121.901779,37.414145],
          [-121.901839,37.414425],
          [-121.901912,37.414718],
          [-121.901982,37.414977],
          [-121.902015,37.415099],
          [-121.902082,37.415362],
          [-121.902168,37.415638],
          [-121.902284,37.415919],
          [-121.902477,37.416388],
          [-121.90218,37.416462],
          [-121.902084,37.416482],
          [-121.902022,37.416495],
          [-121.901977,37.416433],
          [-121.90193,37.416357],
          [-121.90193,37.416301],
          [-121.901953,37.41613],
          [-121.901524,37.414463],
          [-121.901429,37.414368],
          [-121.901344,37.414312],
          [-121.901272,37.414275],
          [-121.901189,37.414262],
          [-121.900919,37.414262],
          [-121.900781,37.414244],
          [-121.900675,37.414226],
          [-121.900546,37.41416],
          [-121.900385,37.414083],
          [-121.900122,37.41393],
          [-121.899954,37.413833],
          [-121.899784,37.413734],
          [-121.899624,37.413641],
          [-121.899377,37.413497],
          [-121.899273,37.413429],
          [-121.899234,37.413382],
          [-121.899234,37.413326],
          [-121.899267,37.413266],
          [-121.89933,37.413231],
          [-121.899395,37.413219],
          [-121.899474,37.41324],
          [-121.899544,37.413288],
          [-121.899573,37.413303],
          [-121.899761,37.413407],
          [-121.899927,37.413497],
          [-121.900079,37.413579],
          [-121.900426,37.413567],
          [-121.900862,37.413833],
          [-121.901122,37.413991],
          [-121.901619,37.414293],
          [-121.901839,37.414425],
          [-121.901912,37.414718],
          [-121.901982,37.414977],
          [-121.902015,37.415099],
          [-121.902082,37.415362],
          [-121.902168,37.415638],
          [-121.902284,37.415919],
          [-121.902477,37.416388],
          [-121.90251,37.416468],
          [-121.902599,37.416664],
          [-121.902691,37.416734],
          [-121.903595,37.418843],
          [-121.904069,37.419916],
          [-121.904285,37.420512]]
        )
      )
      stop_points = @repeated_rsp.stop_pattern.map { |s| Stop.find_by_onestop_id!(s).geometry[:coordinates] }
      has_issues, issues = @repeated_rsp.evaluate_geometry(@trip, stop_points)
      @repeated_rsp.tl_geometry(stop_points, issues)
      distances = @repeated_rsp.calculate_distances
      expect(distances[3]).to be > distances[1]
    end

    it 'can accurately calculate distances when a stop matches to a segment before the previous stop\'s matching segment' do
      # from sfmta
      first_stop = create(:stop,
        onestop_id: "s-9q8yu61fz4-judahst~46thave",
        geometry: Stop::GEOFACTORY.point(-122.505832, 37.760493).to_s
      )
      second_stop = create(:stop,
        onestop_id: "s-9q8yu4pdj1-judah~laplaya~oceanbeach",
        geometry: Stop::GEOFACTORY.point(-122.509011, 37.760363).to_s
      )
      third_stop = create(:stop,
        onestop_id: "s-9q8yu4pbft-judah~laplaya~oceanbeach",
        geometry: Stop::GEOFACTORY.point(-122.508777, 37.76017).to_s
      )

      @tricky_rsp = RouteStopPattern.new(
        stop_pattern: [first_stop.onestop_id, second_stop.onestop_id, third_stop.onestop_id],
        geometry: RouteStopPattern.line_string(
          [[-122.50056,37.76067],
          [-122.50164,37.76062],
          [-122.5027,37.76057],
          [-122.50378,37.76052],
          [-122.50485,37.76048],
          [-122.50592,37.76043],
          [-122.50699,37.76038],
          [-122.50807,37.76033],
          [-122.50814,37.76036],
          [-122.50853,37.76035],
          [-122.5091,37.76033],
          [-122.50918,37.76032],
          [-122.50925,37.76029],
          [-122.50928,37.76023],
          [-122.50929,37.76018],
          [-122.50927,37.76012],
          [-122.50925,37.76009],
          [-122.50921,37.76006],
          [-122.50917,37.76005],
          [-122.50913,37.76004],
          [-122.50908,37.76004]]
        )
      )
      stop_points = @tricky_rsp.stop_pattern.map { |s| Stop.find_by_onestop_id!(s).geometry[:coordinates] }
      has_issues, issues = @tricky_rsp.evaluate_geometry(@trip, stop_points)
      @tricky_rsp.tl_geometry(stop_points, issues)
      distances = @tricky_rsp.calculate_distances
      expect(distances[2]).to be > distances[1]
    end

    it 'calculates the distance of the first stop to be 0 if it is before the first point of a geometry' do
      @rsp.stop_pattern = @rsp.stop_pattern.unshift(create(:stop,
        onestop_id: "s-9q9hwp6epk-before~geometry",
        geometry: Stop::GEOFACTORY.point(-121.5, 37.30).to_s
      ).onestop_id)
      stop_points = @rsp.geometry[:coordinates].unshift([-121.5, 37.30])
      has_issues, issues = @rsp.evaluate_geometry(@trip, stop_points)
      @rsp.tl_geometry(stop_points, issues)
      expect(@rsp.calculate_distances).to match_array([a_value_within(0.1).of(0.0),
                                                       a_value_within(0.1).of(0.0),
                                                       a_value_within(0.1).of(12617.9),
                                                       a_value_within(0.1).of(17001.5)])
    end

    it 'calculates the distance of the last stop to be the length of the line geometry if it is after the last point of the geometry' do
      @rsp.stop_pattern << create(:stop,
       onestop_id: "s-9q9hwp6epk-after~geometry",
       geometry: Stop::GEOFACTORY.point(-122.1, 37.41).to_s
      ).onestop_id
      @rsp.geometry = RouteStopPattern.line_string(@rsp.geometry[:coordinates] << [-122.09, 37.401])
      distances = @rsp.calculate_distances
      expect(distances[3]).to be_within(0.1).of(@rsp[:geometry].length)
      expect(distances).to match_array([a_value_within(0.1).of(0.0),
                                                       a_value_within(0.1).of(12617.9),
                                                       a_value_within(0.1).of(17001.5),
                                                       a_value_within(0.1).of(18447.4)])
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

    it 'assign a fallback distance value equal to the geometry length to the last stop if it is an outlier' do
      last_stop_outlier = create(:stop,
        onestop_id: "s-9q9hwtgq4s-last~outlier",
        geometry: Stop::GEOFACTORY.point(-121.5, 37.3).to_s
      )
      @rsp.stop_pattern << last_stop_outlier.onestop_id
      expect(@rsp.calculate_distances).to match_array([a_value_within(0.1).of(0.0),
                                                              a_value_within(0.1).of(12617.9271),
                                                              a_value_within(0.1).of(17001.5107),
                                                              a_value_within(0.1).of(17001.5107)])
    end

    it 'can calculate distances when two consecutive stop points are identical' do
      identical = create(:stop,
        onestop_id: "s-9q9hwtgq4s-sunnyvaleidentical",
        geometry: stop_b.geometry
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
      expect(@empty_rsp.geometry[:coordinates]).to eq(RouteStopPattern.simplify_geometry(stop_points))
      expect(@empty_rsp.is_generated).to be true
      expect(@empty_rsp.is_modified).to be true
    end
  end
end
