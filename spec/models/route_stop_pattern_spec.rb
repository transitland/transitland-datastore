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
#  trips                              :string           default([]), is an Array
#  created_at                         :datetime         not null
#  updated_at                         :datetime         not null
#  created_or_updated_in_changeset_id :integer
#  route_id                           :integer
#  stop_distances                     :float            default([]), is an Array
#  edited_attributes                  :string           default([]), is an Array
#  geometry_source                    :string
#
# Indexes
#
#  c_rsp_cu_in_changeset                              (created_or_updated_in_changeset_id)
#  index_current_route_stop_patterns_on_onestop_id    (onestop_id) UNIQUE
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

    it 'cannot be created when trip has less than two stop times' do
      sp = [stop_1.onestop_id]
      expect(build(:route_stop_pattern, stop_pattern: sp, geometry: @geom, onestop_id: @onestop_id)
        .valid?
      ).to be false
    end

    it 'can be created when trip has two stop times and only one unique stop' do
      trip = GTFS::Trip.new(trip_id: 'test', shape_id: 'test')
      sp = [stop_1.onestop_id, stop_1.onestop_id]
      stop_time1 = GTFS::StopTime.new(trip_id: trip.trip_id, arrival_time: "01:00:00", departure_time: "01:00:00", stop_id: 'A', stop_sequence: "1")
      stop_time2 = GTFS::StopTime.new(trip_id: trip.trip_id, arrival_time: "02:00:00", departure_time: "02:00:00", stop_id: 'B', stop_sequence: "2")
      stop_times = [stop_time1, stop_time2]
      trip_stop_points = [[-122.401811, 37.706675],[-122.401811, 37.706675]]
      shape_points = []
      rsp = RouteStopPattern.create_from_gtfs(trip, 'r-9q9j-bullet', sp, stop_times, trip_stop_points, shape_points)
      expect(rsp.geometry[:coordinates]).to eq [[-122.40181, 37.70667],[-122.40181, 37.70667]]
      expect(rsp.calculate_distances).to eq [0.0,0.0]
    end

    it 'sets geometry_source based on GTFS ShapeLine' do
      stops = [stop_1, stop_2]
      trip = GTFS::Trip.new(trip_id: 'test', shape_id: 'test')
      shape_line1 = GTFS::ShapeLine.from_shapes(stops.each_with_index.map { |stop, i| GTFS::Shape.new(shape_id: '123', shape_pt_sequence: i, shape_pt_lon: stop.geometry(as: :wkt).lon, shape_pt_lat: stop.geometry(as: :wkt).lat) })
      shape_line2 = GTFS::ShapeLine.from_shapes(stops.each_with_index.map { |stop, i| GTFS::Shape.new(shape_id: '123', shape_pt_sequence: i, shape_pt_lon: stop.geometry(as: :wkt).lon, shape_pt_lat: stop.geometry(as: :wkt).lat, shape_dist_traveled: i) })
      stop_pattern = stops.map(&:onestop_id)
      stop_time1 = GTFS::StopTime.new(trip_id: trip.trip_id, arrival_time: "01:00:00", departure_time: "01:00:00", stop_id: 'A', stop_sequence: "1")
      stop_time2 = GTFS::StopTime.new(trip_id: trip.trip_id, arrival_time: "02:00:00", departure_time: "02:00:00", stop_id: 'B', stop_sequence: "2")
      stop_times = [stop_time1, stop_time2]
      trip_stop_points = [[-122.401811, 37.706675],[-122.401811, 37.706675]]
      # Check
      rsp = RouteStopPattern.create_from_gtfs(trip, 'r-9q9j-bullet', stop_pattern, stop_times, trip_stop_points, [])
      expect(rsp.geometry_source).to eq :trip_stop_points
      rsp = RouteStopPattern.create_from_gtfs(trip, 'r-9q9j-bullet', stop_pattern, stop_times, trip_stop_points, shape_line1)
      expect(rsp.geometry_source).to eq :shapes_txt

      # Both shapes and stop_times must have shape_dist_traveled to be effective
      stop_time1.shape_dist_traveled = "0.0"
      stop_time2.shape_dist_traveled = "1.0" # using a fake distance
      rsp = RouteStopPattern.create_from_gtfs(trip, 'r-9q9j-bullet', stop_pattern, stop_times, trip_stop_points, shape_line2)
      expect(rsp.geometry_source).to eq :shapes_txt_with_dist_traveled
    end

    it 'cannot be created when stop_distances size does not match stop_pattern size' do
      rsp = build(:route_stop_pattern, stop_pattern: @sp, geometry: @geom, onestop_id: @onestop_id)
      rsp.stop_distances = []
      expect(rsp.valid?).to be false
      expect(rsp.errors[:stop_distances].size).to eq(1)
    end

    it 'is not valid when geometry has less than two points' do
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
      expect(rsp.valid?).to be false
    end
  end

  it 'can create new geometry' do
    expect(RouteStopPattern.line_string([[1,2],[2,2]]).is_a?(RGeo::Geographic::SphericalLineStringImpl)).to be true
  end

  it '#set_precision' do
    expect(RouteStopPattern.set_precision([[-122.0123456,45.01234567],
                                           [-122.9123478,45.91234589]])).to match_array([[-122.01235,45.01235],[-122.91235,45.91235]])
  end

  it '.with_all_stops' do
    rsp = create(:route_stop_pattern, stop_pattern: @sp, geometry: @geom, onestop_id: @onestop_id)
    expect(RouteStopPattern.with_all_stops('s-9q8yw8y448-bayshorecaltrainstation')).to match_array([rsp])
    expect(RouteStopPattern.with_all_stops('s-9q8yw8y448-bayshorecaltrainstation,s-9q8yyugptw-sanfranciscocaltrainstation')).to match_array([rsp])
    expect(RouteStopPattern.with_all_stops('s-9q9k659e3r-sanjosecaltrainstation')).to match_array([])
    # Stop 's-9q9k659e3r-sanjosecaltrainstation' does not exist
    expect(RouteStopPattern.with_all_stops('s-9q8yw8y448-bayshorecaltrainstation,s-9q9k659e3r-sanjosecaltrainstation')).to match_array([])
  end

  it '.with_any_stops' do
    rsp = create(:route_stop_pattern, stop_pattern: @sp, geometry: @geom, onestop_id: @onestop_id)
    expect(RouteStopPattern.with_any_stops(['s-9q8yw8y448-bayshorecaltrainstation'])).to match_array([rsp])
    expect(RouteStopPattern.with_any_stops(['s-9q9k659e3r-sanjosecaltrainstation'])).to match_array([])
    # Stop 's-9q9k659e3r-sanjosecaltrainstation' does not exist yet
    expect(RouteStopPattern.with_any_stops(['s-9q8yw8y448-bayshorecaltrainstation','s-9q9k659e3r-sanjosecaltrainstation'])).to match_array([rsp])
    # create Stop 's-9q9k659e3r-sanjosecaltrainstation'
    stop = create(:stop, onestop_id: 's-9q9k659e3r-sanjosecaltrainstation')
    rsp2 = create(:route_stop_pattern, stop_pattern: [@sp[0],stop.onestop_id], geometry: @geom)
    expect(RouteStopPattern.with_any_stops(['s-9q8yw8y448-bayshorecaltrainstation','s-9q9k659e3r-sanjosecaltrainstation'])).to match_array([rsp, rsp2])
  end

  it 'can be found by trips' do
    rsp = create(:route_stop_pattern, stop_pattern: @sp, geometry: @geom, onestop_id: @onestop_id, trips: ['trip1','trip2'])
    expect(RouteStopPattern.with_trips('trip1')).to match_array([rsp])
    expect(RouteStopPattern.with_trips('trip1,trip2')).to match_array([rsp])
    expect(RouteStopPattern.with_trips('trip3')).to match_array([])
    expect(RouteStopPattern.with_trips('trip1,trip3')).to match_array([])
  end

  it 'ordered_ssp_trip_chunks' do
    route = create(:route, onestop_id: @onestop_id)
    rsp = create(:route_stop_pattern, stop_pattern: @sp, geometry: @geom, onestop_id: @onestop_id, trips: ['trip1','trip2'])
    ssp_1a = create(:schedule_stop_pair, origin: stop_a, origin_departure_time: "09:00:00", destination: stop_b, route: route, route_stop_pattern: rsp, trip: 'trip1')
    ssp_1b = create(:schedule_stop_pair, origin: stop_b, origin_departure_time: "09:30:00", destination: stop_c, route: route, route_stop_pattern: rsp, trip: 'trip1')
    ssp_2a = create(:schedule_stop_pair, origin: stop_a, origin_departure_time: "10:00:00", destination: stop_b, route: route, route_stop_pattern: rsp, trip: 'trip2')
    ssp_2b = create(:schedule_stop_pair, origin: stop_b, origin_departure_time: "10:30:00", destination: stop_c, route: route, route_stop_pattern: rsp, trip: 'trip2')
    chunks = []
    rsp.ordered_ssp_trip_chunks { |trip_chunk|
      ssps = []
      trip_chunk.each_with_index do |ssp, i|
        ssps << ssp
      end
      chunks << ssps
    }
    expect(chunks).to match_array([[ssp_1a, ssp_1b],[ssp_2a, ssp_2b]])
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

    it '#shape_dist_traveled' do
      feed, feed_version = load_feed(feed_version_name: :feed_version_nj_path, import_level: 1)
      gtfs = GTFS::Source.build(feed_version.file.file.file)
      rsp = feed.imported_route_stop_patterns.first
      tl_stops = rsp.stop_pattern.map{ |stop_onestop_id| Stop.find_by_onestop_id!(stop_onestop_id) }
      trip = gtfs.trips.detect{|trip| trip.id == rsp.trips.first}
      trip_stop_times = []
      gtfs.trip_stop_times(trips=[trip]){ |trip, stop_times| trip_stop_times = stop_times }
      expect(rsp.gtfs_shape_dist_traveled(trip_stop_times, tl_stops, gtfs.shape_line(trip.shape_id).shape_dist_traveled)).to match_array([0.0, 1166.3, 2507.7, 4313.8])
    end

    it 'no distance issues with RSPs generated from trip stop points' do
      feed, feed_version = load_feed(feed_version_name: :feed_version_seattle_childrens, import_level: 1)
      expect(RouteStopPattern.find_by_onestop_id!('r-c23p1-sch~gold-10c68e-2ef1dd').stop_distances).to match_array([a_value_within(0.1).of(0.0), a_value_within(0.1).of(2070.3), a_value_within(0.1).of(4140.7)])
      expect(Issue.where(issue_type: 'distance_calculation_inaccurate').size).to eq 0
    end

    it '#fallback_distances' do
      expect(@rsp.stop_distances).to match_array([])
      @rsp.fallback_distances
      expect(@rsp.stop_distances).to match_array([a_value_within(0.1).of(0.0),
                                                              a_value_within(0.1).of(12617.9),
                                                              a_value_within(0.1).of(17001.5)])
    end

    it 'stores distances in stop_distances attribute' do
      @rsp.calculate_distances
      expect(@rsp.stop_distances.count).to eq 3
    end

    it 'can calculate distances when the geometry and stop coordinates are equal' do
      expect(@rsp.calculate_distances).to match_array([a_value_within(0.1).of(0.0),
                                                              a_value_within(0.1).of(12617.9271),
                                                              a_value_within(0.1).of(17001.5107)])
    end

    it 'can calculate distances when coordinates are repeated' do
      @feed, @feed_version = load_feed(feed_version_name: :feed_version_mtanyctbusstatenisland_trip_YU_S6_Weekday_030000_MISC_112, import_level: 1)
      distances = @feed.imported_route_stop_patterns[0].calculate_distances
      # expect all distances to be increasing
      expect(distances[1..-1].each_with_index.map { |v, i| v > distances[i] }.all?).to be true
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

    it '#distance_along_line_to_nearest' do
      cartesian_line = @rsp.cartesian_cast(@rsp[:geometry])
      # this is the midpoint between stop_a and stop_b, with a little offset
      target_point = @rsp.cartesian_cast(Stop::GEOFACTORY.point(-121.9664615, 37.36))
      locators = cartesian_line.locators(target_point)
      i = @rsp.nearest_segment_index(locators, target_point, 0, locators.size-1)
      nearest_point = @rsp.nearest_point(locators, i)
      expect(@rsp.distance_along_line_to_nearest(cartesian_line, nearest_point, i)).to be_within(0.1).of(6508.84)
    end

    it '#nearest_segment_index' do
      coords = @rsp.geometry[:coordinates].concat [stop_b.geometry[:coordinates],stop_a.geometry[:coordinates]]
      @rsp.geometry = RouteStopPattern.line_string(coords)
      cartesian_line = @rsp.cartesian_cast(@rsp[:geometry])
      # this is the midpoint between stop_a and stop_b, with a little offset
      target_point = @rsp.cartesian_cast(Stop::GEOFACTORY.point(-121.9664615, 37.36))
      locators = cartesian_line.locators(target_point)
      i = @rsp.nearest_segment_index(locators, target_point, 0, locators.size - 1)
      expect(i).to eq 0
      i = @rsp.nearest_segment_index(locators, target_point, 0, locators.size - 1, first=false)
      expect(i).to eq locators.size - 1
    end

    it 'accurately calculates the distances of nyc staten island ferry 2-stop routes with before/after stops' do
      @feed, @feed_version = load_feed(feed_version_name: :feed_version_nycdotsiferry, import_level: 2)
      expect(@feed.imported_route_stop_patterns[0].calculate_distances).to match_array([0.0, 8138.0])
      expect(@feed.imported_route_stop_patterns[1].calculate_distances).to match_array([3.2, 8141.2])
    end

    it 'accurately calculates the distances of a route with stops along the line that traversed over itself in the opposite direction' do
      # see https://transit.land/documentation/datastore/rome_01_part_1.png
      # and https://transit.land/documentation/datastore/rome_01_part_2.png
      @feed, @feed_version = load_feed(feed_version_name: :feed_version_rome, import_level: 2)
      expect(@feed.imported_route_stop_patterns[0].calculate_distances).to match_array([0.6,639.6,817.5,1034.9,1250.2,1424.2,1793.5,1929.2,2162.2,2429.9,2579.6,2735.3,3022.6,3217.8,3407.3,3646.6,3804.4,3969.1,4128.3,4302.6,4482.1,4586.9,4869.5,5242.7,5510.4,5695.6,5871.4,6112.9,6269.6,6334.1,6528.8,6715.4,6863.0,7140.2,7689.8])
    end

    it 'accurately calculates the distances of a route with stops along the line that traversed over itself in the opposite direction, but closest match was segment in opposite direction' do
      @feed, @feed_version = load_feed(feed_version_name: :feed_version_vta_1965654, import_level: 2)
      expect(@feed.imported_route_stop_patterns[0].calculate_distances).to match_array([0.0,1490.8,1818.6,2478.0,2928.5,3167.2,3584.7,4079.4,4360.6,4784.1,4970.5,5168.1,5340.5,5599.0,6023.2,6483.9,6770.0,7469.3])
    end

    it 'calculates the first stop distance correctly' do
      # from sfmta route 54 and for regression. case where first stop is not a 'before' stop
      # see https://transit.land/documentation/datastore/first_stop_correct_distance.png
      @feed, @feed_version = load_feed(feed_version_name: :feed_version_sfmta_6720619, import_level: 2)
      expect(@feed.imported_route_stop_patterns[0].calculate_distances[0]).to be_within(0.1).of(201.1)
    end

    it 'can accurately calculate distances when a stop is repeated.' do
      # from f-9q9-vta, r-9q9k-66.
      # see https://transit.land/documentation/datastore/repeated_stop_vta_66.png
      @feed, @feed_version = load_feed(feed_version_name: :feed_version_vta_1930705, import_level: 2)
      distances = @feed.imported_route_stop_patterns[0].calculate_distances
      expect(distances[77]).to be > distances[75]
    end

    it 'can accurately calculate distances when a stop matches to a segment before the previous stop\'s matching segment' do
      # from sfmta, N-OWL route.
      # See https://transit.land/documentation/datastore/previous_segment_1_sfmta_n~owl.png
      # and https://transit.land/documentation/datastore/previous_segment_2_sfmta_n~owl.png
      @feed, @feed_version = load_feed(feed_version_name: :feed_version_sfmta_6731593, import_level: 2)
      tricky_rsp = @feed.imported_route_stop_patterns[0]
      distances = tricky_rsp.calculate_distances
      expect(distances[-1]).to be > distances[-2]
    end

    it 'calculates the distance of the first stop to be 0 if it is before the first point of a geometry' do
      @rsp.stop_pattern = @rsp.stop_pattern.unshift(create(:stop,
        onestop_id: "s-9q9hwp6epk-before~geometry",
        geometry: Stop::GEOFACTORY.point(-121.5, 37.30).to_s
      ).onestop_id)
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
                                                              a_value_within(0.1).of(14809.7),
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

    it 'can readjust distances when stops match to the same segment out of order' do
      @feed, @feed_version = load_feed(feed_version_name: :feed_version_sfmta_7310245, import_level: 1)
      distances = @feed.imported_route_stop_patterns[0].calculate_distances
      # expect all distances to be increasing
      expect(distances[1..-1].each_with_index.map { |v, i| v > distances[i] }.all?).to be true
    end

    it 'accurately calculates distances if the last stop is an after? stop' do
      geom = RouteStopPattern.line_string([[-122.41, 37.65],[-122.401811, 37.706675],[-122.394935, 37.776348]])
      @rsp.geometry = geom
      stop_a.update_column(:geometry, RouteStopPattern::GEOFACTORY.point(-122.41, 37.65))
      stop_b.update_column(:geometry, RouteStopPattern::GEOFACTORY.point(-122.401811, 37.706675))
      stop_c.update_column(:geometry, RouteStopPattern::GEOFACTORY.point(-122.38, 37.78))
      expect(@rsp.calculate_distances).to match_array([a_value_within(0.1).of(0.0),
                                                              a_value_within(0.1).of(6350.2),
                                                              a_value_within(0.1).of(14129.7)])
    end

    it 'accurately calculates distances if the last stop is close to the line and is not an after? stop' do
      geom = RouteStopPattern.line_string([[-122.41, 37.65],[-122.401811, 37.706675],[-122.394935, 37.776348]])
      @rsp.geometry = geom
      stop_a.update_column(:geometry, RouteStopPattern::GEOFACTORY.point(-122.41, 37.65))
      stop_b.update_column(:geometry, RouteStopPattern::GEOFACTORY.point(-122.401811, 37.706675))
      stop_c.update_column(:geometry, RouteStopPattern::GEOFACTORY.point(-122.3975, 37.741))
      expect(@rsp.calculate_distances).to match_array([a_value_within(0.1).of(0.0),
                                                              a_value_within(0.1).of(6350.2),
                                                              a_value_within(0.1).of(10192.9)])
    end

    it 'accurately calculates distances if the last stop is not an after? stop, but not close enough to the line' do
      # last stop distance should be the length of the line, ~ 14129.7
      geom = RouteStopPattern.line_string([[-122.41, 37.65],[-122.401811, 37.706675],[-122.394935, 37.776348]])
      @rsp.geometry = geom
      stop_a.update_column(:geometry, RouteStopPattern::GEOFACTORY.point(-122.41, 37.65))
      stop_b.update_column(:geometry, RouteStopPattern::GEOFACTORY.point(-122.401811, 37.706675))
      stop_c.update_column(:geometry, RouteStopPattern::GEOFACTORY.point(-122.39, 37.77))
      expect(@rsp.calculate_distances).to match_array([a_value_within(0.1).of(0.0),
                                                              a_value_within(0.1).of(6350.2),
                                                              a_value_within(0.1).of(14129.7)])
    end

    it 'accurately calculates distances if the first stop is a before? stop' do
      geom = RouteStopPattern.line_string([[-122.401811, 37.706675],[-122.394935, 37.776348],[-122.39, 37.84]])
      @rsp.geometry = geom
      stop_a.update_column(:geometry, RouteStopPattern::GEOFACTORY.point(-122.41, 37.69))
      stop_b.update_column(:geometry, RouteStopPattern::GEOFACTORY.point(-122.394935, 37.776348))
      stop_c.update_column(:geometry, RouteStopPattern::GEOFACTORY.point(-122.39, 37.84))
      expect(@rsp.calculate_distances).to match_array([a_value_within(0.1).of(0.0),
                                                              a_value_within(0.1).of(7779.5),
                                                              a_value_within(0.1).of(14878.5)])
    end

    it 'accurately calculates distances if the first stop is close to the line and not a before? stop' do
      geom = RouteStopPattern.line_string([[-122.401811, 37.706675],[-122.394935, 37.776348],[-122.39, 37.84]])
      @rsp.geometry = geom
      stop_a.update_column(:geometry, RouteStopPattern::GEOFACTORY.point(-122.40182, 37.7067))
      stop_b.update_column(:geometry, RouteStopPattern::GEOFACTORY.point(-122.394935, 37.776348))
      stop_c.update_column(:geometry, RouteStopPattern::GEOFACTORY.point(-122.39, 37.84))
      expect(@rsp.calculate_distances).to match_array([a_value_within(0.1).of(2.7),
                                                              a_value_within(0.1).of(7779.5),
                                                              a_value_within(0.1).of(14878.5)])
    end

    it 'accurately calculates distances if the first stop is not a before? stop, but not close enough to the line' do
      # consequently the first stop distance should be 0.0
      geom = RouteStopPattern.line_string([[-122.401811, 37.706675],[-122.394935, 37.776348],[-122.39, 37.84]])
      @rsp.geometry = geom
      stop_a.update_column(:geometry, RouteStopPattern::GEOFACTORY.point(-122.40182, 37.72))
      stop_b.update_column(:geometry, RouteStopPattern::GEOFACTORY.point(-122.394935, 37.776348))
      stop_c.update_column(:geometry, RouteStopPattern::GEOFACTORY.point(-122.39, 37.84))
      expect(@rsp.calculate_distances).to match_array([a_value_within(0.1).of(0.0),
                                                              a_value_within(0.1).of(7779.5),
                                                              a_value_within(0.1).of(14878.5)])
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

  context 'without shape or shape points' do
    it 'generated RSP geometries from stop points when no shapes' do
      @feed, @feed_version = load_feed(feed_version_name: :feed_version_example_no_shapes, import_level: 1)
      rsp = @feed.imported_route_stop_patterns[0]
      expect(rsp.geometry[:coordinates]).to eq rsp.stop_pattern.map{ |onestop_id| Stop.find_by_onestop_id!(onestop_id).geometry[:coordinates].map{ |c| c.round(RouteStopPattern::COORDINATE_PRECISION)} }
    end
  end
end
