describe Geometry do

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

  context 'distance calculation' do
    before(:each) do
      @sp = [stop_a.onestop_id,
             stop_b.onestop_id,
             stop_c.onestop_id]
      @geom = Geometry::LineString.line_string([stop_a.geometry[:coordinates],
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

    it '#distance_along_line_to_nearest_point' do
      cartesian_line = Geometry::DistanceCalculation.cartesian_cast(@rsp[:geometry])
      # this is the midpoint between stop_a and stop_b, with a little offset
      target_point = Geometry::DistanceCalculation.cartesian_cast(Stop::GEOFACTORY.point(-121.9664615, 37.36))
      locators = cartesian_line.locators(target_point)
      i = Geometry::DistanceCalculation.index_of_closest_match_line_segment(locators, 0, locators.size-1, target_point)
      nearest_point = Geometry::LineString.nearest_point_on_line(locators, i)
      expect(Geometry::LineString.distance_along_line_to_nearest_point(cartesian_line, nearest_point, i)).to be_within(0.1).of(6508.84)
    end

    it '#index_of_closest_match_line_segment' do
      coords = @rsp.geometry[:coordinates].concat [stop_b.geometry[:coordinates],stop_a.geometry[:coordinates]]
      @rsp.geometry = Geometry::LineString.line_string(coords)
      cartesian_line = Geometry::DistanceCalculation.cartesian_cast(@rsp[:geometry])
      # this is the midpoint between stop_a and stop_b, with a little offset
      mid = Stop::GEOFACTORY.point(-121.9664615, 37.36)
      target_point = Geometry::DistanceCalculation.cartesian_cast(mid)
      locators = cartesian_line.locators(target_point)
      i = Geometry::DistanceCalculation.index_of_closest_match_line_segment(locators, 0, locators.size - 1, target_point)
      expect(i).to eq 0
    end

    context '#shape_dist_traveled' do
      it '#shape_dist_traveled' do
        # this feed also contains duplicated shape points to test seg_index incrementing
        feed, feed_version = load_feed(feed_version_name: :feed_version_nj_path, import_level: 1)
        gtfs = GTFS::Source.build(feed_version.file.file.file)
        rsp = feed.imported_route_stop_patterns.first
        tl_stops = rsp.stop_pattern.map{ |stop_onestop_id| Stop.find_by_onestop_id!(stop_onestop_id) }
        trip = gtfs.trips.detect{|trip| trip.id == rsp.trips.first}
        trip_stop_times = []
        gtfs.trip_stop_times(trips=[trip]){ |trip, stop_times| trip_stop_times = stop_times }
        expect(Geometry::DistanceCalculation.gtfs_shape_dist_traveled(rsp, trip_stop_times, tl_stops, gtfs.shape_line(trip.shape_id).shape_dist_traveled)).to match_array([0.0, 1166.3, 2507.7, 4313.8])
      end

      it 'sets stop distance to the geometry length when stop_time\'s shape_dist_traveled is greater than the last shape point' do
        # the last stop time of trip 636342A5394B6507 is set to "3.0" in the GTFS, greater than "2.677" in shapes.txt
        feed, feed_version = load_feed(feed_version_name: :feed_version_nj_path_last_stop_past_edge, import_level: 1)
        expect(RouteStopPattern.first.stop_distances).to match_array([0.0, 1166.3, 2507.7, 4313.8])
        expect(RouteStopPattern.first[:geometry].length).to be_within(0.1).of(4313.8)
        expect(RouteStopPattern.last.stop_distances).to match_array([0.0, 1805.2, 3145.8, 4320.6])
        expect(RouteStopPattern.last[:geometry].length).to be_within(0.1).of(4320.6)
      end

      it 'sets stop distance to 0.0 when stop_time\'s shape_dist_traveled is less than the first shape point' do
        # the first shape point of trip 636342A5394B6507 is set to "0.10" while the first stop time dist is 0.0
        feed, feed_version = load_feed(feed_version_name: :feed_version_nj_path_first_stop_before_edge, import_level: 1)
        gtfs = GTFS::Source.build(feed_version.file.file.file)
        expect(RouteStopPattern.first.stop_distances).to match_array([0.0, 1166.3, 2507.7, 4313.8])
        expect(RouteStopPattern.last.stop_distances).to match_array([0.0, 1805.2, 3145.8, 4320.6])
      end

      it 'shape_dist_traveled has equal distances, but calculate_distances does not' do
        feed, feed_version = load_feed(feed_version_name: :feed_version_wmata_75098, import_level: 1)
        gtfs = GTFS::Source.build(feed_version.file.file.file)
        rsp = feed.imported_route_stop_patterns.first
        tl_stops = rsp.stop_pattern.map{ |stop_onestop_id| Stop.find_by_onestop_id!(stop_onestop_id) }
        trip = gtfs.trips.detect{|trip| trip.id == rsp.trips.first}
        trip_stop_times = []
        gtfs.trip_stop_times(trips=[trip]){ |trip, stop_times| trip_stop_times = stop_times }
        expect(Geometry::DistanceCalculation.gtfs_shape_dist_traveled(rsp, trip_stop_times, tl_stops, gtfs.shape_line(trip.shape_id).shape_dist_traveled)).to match_array([0.0,399.4,553.4,761.0,906.2,1145.0,1385.2,1586.9,1774.2,2030.3,2214.0,2519.2,2764.1,2885.8,3057.6,3194.0,3429.4,3610.4,4359.9,4359.9,4910.9,5135.1,5363.9,5702.6,5885.2,6103.7,6465.9,6802.6,7415.0,7663.8,8118.1,8358.9,8588.2,8793.5,8963.8,9152.1])
        expect(Geometry::DistanceCalculation.calculate_distances(rsp)).to match_array([0.3,406.7,552.9,761.4,906.0,1144.8,1385.5,1586.9,1774.2,2030.7,2214.5,2519.2,2763.9,2885.8,3057.2,3194.0,3429.1,3610.1,4363.4,4363.8,4915.4,5134.9,5363.7,5702.6,5885.2,6103.7,6465.9,6835.4,7357.5,7672.5,8118.1,8359.0,8588.2,8793.5,8963.4,9151.9])
      end
    end

    it 'no distance issues with RSPs generated from trip stop points' do
      feed, feed_version = load_feed(feed_version_name: :feed_version_seattle_childrens, import_level: 1)
      expect(RouteStopPattern.find_by_onestop_id!('r-c23p1-sch~gold-10c68e-2ef1dd').stop_distances).to match_array([a_value_within(0.1).of(0.0), a_value_within(0.1).of(2070.3), a_value_within(0.1).of(4140.7)])
      expect(Issue.where(issue_type: 'distance_calculation_inaccurate').size).to eq 0
    end

    it '#fallback_distances' do
      expect(@rsp.stop_distances).to match_array([])
      Geometry::DistanceCalculation.fallback_distances(@rsp)
      expect(@rsp.stop_distances).to match_array([a_value_within(0.1).of(0.0),
                                                              a_value_within(0.1).of(12617.9),
                                                              a_value_within(0.1).of(17001.5)])
    end

    it 'stores distances in stop_distances attribute' do
      Geometry::DistanceCalculation.calculate_distances(@rsp)
      expect(@rsp.stop_distances.count).to eq 3
    end

    it 'can calculate distances when the geometry and stop coordinates are equal' do
      expect(Geometry::DistanceCalculation.calculate_distances(@rsp)).to match_array([a_value_within(0.1).of(0.0),
                                                              a_value_within(0.1).of(12617.9271),
                                                              a_value_within(0.1).of(17001.5107)])
    end

    it 'can calculate distances when coordinates are repeated' do
      @feed, @feed_version = load_feed(feed_version_name: :feed_version_mtanyctbusstatenisland_trip_YU_S6_Weekday_030000_MISC_112, import_level: 1)
      distances = Geometry::DistanceCalculation.calculate_distances(@feed.imported_route_stop_patterns[0])
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
      expect(Geometry::DistanceCalculation.calculate_distances(@rsp)).to match_array([a_value_within(0.1).of(0.0),
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
      expect(Geometry::DistanceCalculation.calculate_distances(@rsp)).to match_array([a_value_within(0.1).of(0.0),
                                                              a_value_within(0.1).of(12617.9271),
                                                              a_value_within(0.5).of(14809.7189),
                                                              a_value_within(0.1).of(17001.5107)])
    end

    it 'accurately calculates the distances of nyc staten island ferry 2-stop routes with before/after stops' do
      @feed, @feed_version = load_feed(feed_version_name: :feed_version_nycdotsiferry, import_level: 1)
      expect(Geometry::DistanceCalculation.calculate_distances(@feed.imported_route_stop_patterns[0])).to match_array([0.0, 8138.0])
      expect(Geometry::DistanceCalculation.calculate_distances(@feed.imported_route_stop_patterns[1])).to match_array([3.2, 8141.2])
    end

    it 'accurately calculates the distances of a route with stops along the line that traversed over itself in the opposite direction' do
      # see https://transit.land/documentation/datastore/rome_01_part_1.png
      # and https://transit.land/documentation/datastore/rome_01_part_2.png
      @feed, @feed_version = load_feed(feed_version_name: :feed_version_rome, import_level: 1)
      expect(Geometry::DistanceCalculation.calculate_distances(@feed.imported_route_stop_patterns[0])).to match_array([0.6,639.6,817.5,1034.9,1250.2,1424.2,1793.5,1929.2,2162.2,2429.9,2579.6,2735.3,3022.6,3217.8,3407.3,3646.6,3804.4,3969.1,4128.3,4302.6,4482.1,4586.9,4869.5,5242.7,5510.4,5695.6,5871.4,6112.9,6269.6,6334.1,6528.8,6715.4,6863.0,7140.2,7689.8])
    end

    it 'accurately calculates the distances of a route with stops along the line that traversed over itself in the opposite direction, but closest match was segment in opposite direction' do
      @feed, @feed_version = load_feed(feed_version_name: :feed_version_vta_1965654, import_level: 1)
      expect(Geometry::DistanceCalculation.calculate_distances(@feed.imported_route_stop_patterns[0])).to match_array([0.0,1490.8,1818.6,2478.0,2928.5,3167.2,3583.3,4079.4,4360.6,4784.1,4970.5,5168.1,5340.5,5599.0,6023.2,6483.9,6770.0,7469.3])
    end

    it 'calculates the first stop distance correctly' do
      # from sfmta route 54 and for regression. case where first stop is not a 'before' stop
      # see https://transit.land/documentation/datastore/first_stop_correct_distance.png
      @feed, @feed_version = load_feed(feed_version_name: :feed_version_sfmta_6720619, import_level: 1)
      distances = Geometry::DistanceCalculation.calculate_distances(@feed.imported_route_stop_patterns[0])
      expect(distances[0]).to be_within(0.1).of(201.1)
    end

    it 'can accurately calculate distances when a stop is repeated.' do
      # from f-9q9-vta, r-9q9k-66.
      # see https://transit.land/documentation/datastore/repeated_stop_vta_66.png
      @feed, @feed_version = load_feed(feed_version_name: :feed_version_vta_1930705, import_level: 1)
      distances = Geometry::DistanceCalculation.calculate_distances(@feed.imported_route_stop_patterns[0])
      expect(distances[77]).to be > distances[75]
    end

    it 'can accurately calculate distances when a stop matches to a segment before the previous stop\'s matching segment' do
      # from sfmta, N-OWL route.
      # See https://transit.land/documentation/datastore/previous_segment_1_sfmta_n~owl.png
      # and https://transit.land/documentation/datastore/previous_segment_2_sfmta_n~owl.png
      @feed, @feed_version = load_feed(feed_version_name: :feed_version_sfmta_6731593, import_level: 1)
      tricky_rsp = @feed.imported_route_stop_patterns[0]
      distances = Geometry::DistanceCalculation.calculate_distances(tricky_rsp)
      expect(distances[-1]).to be > distances[-2]
    end

    it 'calculates the distance of the first stop to be 0 if it is before the first point of a geometry' do
      @rsp.stop_pattern = @rsp.stop_pattern.unshift(create(:stop,
        onestop_id: "s-9q9hwp6epk-before~geometry",
        geometry: Stop::GEOFACTORY.point(-121.5, 37.30).to_s
      ).onestop_id)
      expect(Geometry::DistanceCalculation.calculate_distances(@rsp)).to match_array([a_value_within(0.1).of(0.0),
                                                       a_value_within(0.1).of(0.0),
                                                       a_value_within(0.1).of(12617.9),
                                                       a_value_within(0.1).of(17001.5)])
    end

    it 'calculates the distance of the last stop to be the length of the line geometry if it is after the last point of the geometry' do
      @rsp.stop_pattern << create(:stop,
       onestop_id: "s-9q9hwp6epk-after~geometry",
       geometry: Stop::GEOFACTORY.point(-122.1, 37.41).to_s
      ).onestop_id
      @rsp.geometry = Geometry::LineString.line_string(@rsp.geometry[:coordinates] << [-122.09, 37.401])
      distances = Geometry::DistanceCalculation.calculate_distances(@rsp)
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
      expect(Geometry::DistanceCalculation.calculate_distances(@rsp)).to match_array([a_value_within(0.1).of(0.0),
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
      expect(Geometry::DistanceCalculation.calculate_distances(@rsp)).to match_array([a_value_within(0.1).of(0.0),
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
      expect(Geometry::DistanceCalculation.calculate_distances(@rsp)).to match_array([a_value_within(0.1).of(0.0),
                                                              a_value_within(0.1).of(12617.9271),
                                                              a_value_within(0.1).of(12617.9271),
                                                              a_value_within(0.1).of(17001.5107)])
    end

    it 'can readjust distances when stops match to the same segment out of order' do
      @feed, @feed_version = load_feed(feed_version_name: :feed_version_sfmta_7310245, import_level: 1)
      distances = Geometry::DistanceCalculation.calculate_distances(@feed.imported_route_stop_patterns[0])
      # expect all distances to be increasing
      expect(distances[1..-1].each_with_index.map { |v, i| v > distances[i] }.all?).to be true
    end

    it 'accurately calculates distances if the last stop is an after? stop' do
      geom = Geometry::LineString.line_string([[-122.41, 37.65],[-122.401811, 37.706675],[-122.394935, 37.776348]])
      @rsp.geometry = geom
      stop_a.update_column(:geometry, RouteStopPattern::GEOFACTORY.point(-122.41, 37.65))
      stop_b.update_column(:geometry, RouteStopPattern::GEOFACTORY.point(-122.401811, 37.706675))
      stop_c.update_column(:geometry, RouteStopPattern::GEOFACTORY.point(-122.38, 37.78))
      expect(Geometry::DistanceCalculation.calculate_distances(@rsp)).to match_array([a_value_within(0.1).of(0.0),
                                                              a_value_within(0.1).of(6350.2),
                                                              a_value_within(0.1).of(14129.7)])
    end

    it 'accurately calculates distances if the last stop is close to the line and is not an after? stop' do
      geom = Geometry::LineString.line_string([[-122.41, 37.65],[-122.401811, 37.706675],[-122.394935, 37.776348]])
      @rsp.geometry = geom
      stop_a.update_column(:geometry, RouteStopPattern::GEOFACTORY.point(-122.41, 37.65))
      stop_b.update_column(:geometry, RouteStopPattern::GEOFACTORY.point(-122.401811, 37.706675))
      stop_c.update_column(:geometry, RouteStopPattern::GEOFACTORY.point(-122.3975, 37.741))
      expect(Geometry::DistanceCalculation.calculate_distances(@rsp)).to match_array([a_value_within(0.1).of(0.0),
                                                              a_value_within(0.1).of(6350.2),
                                                              a_value_within(0.1).of(10192.9)])
    end

    it 'accurately calculates distances if the last stop is not an after? stop, but not close enough to the line' do
      # last stop distance should be the length of the line, ~ 14129.7
      geom = Geometry::LineString.line_string([[-122.41, 37.65],[-122.401811, 37.706675],[-122.394935, 37.776348]])
      @rsp.geometry = geom
      stop_a.update_column(:geometry, RouteStopPattern::GEOFACTORY.point(-122.41, 37.65))
      stop_b.update_column(:geometry, RouteStopPattern::GEOFACTORY.point(-122.401811, 37.706675))
      stop_c.update_column(:geometry, RouteStopPattern::GEOFACTORY.point(-122.39, 37.77))
      expect(Geometry::DistanceCalculation.calculate_distances(@rsp)).to match_array([a_value_within(0.1).of(0.0),
                                                              a_value_within(0.1).of(6350.2),
                                                              a_value_within(0.1).of(14129.7)])
    end

    it 'accurately calculates distances if the first stop is a before? stop' do
      geom = Geometry::LineString.line_string([[-122.401811, 37.706675],[-122.394935, 37.776348],[-122.39, 37.84]])
      @rsp.geometry = geom
      stop_a.update_column(:geometry, RouteStopPattern::GEOFACTORY.point(-122.41, 37.69))
      stop_b.update_column(:geometry, RouteStopPattern::GEOFACTORY.point(-122.394935, 37.776348))
      stop_c.update_column(:geometry, RouteStopPattern::GEOFACTORY.point(-122.39, 37.84))
      expect(Geometry::DistanceCalculation.calculate_distances(@rsp)).to match_array([a_value_within(0.1).of(0.0),
                                                              a_value_within(0.1).of(7779.5),
                                                              a_value_within(0.1).of(14878.5)])
    end

    it 'accurately calculates distances if the first stop is close to the line and not a before? stop' do
      geom = Geometry::LineString.line_string([[-122.401811, 37.706675],[-122.394935, 37.776348],[-122.39, 37.84]])
      @rsp.geometry = geom
      stop_a.update_column(:geometry, RouteStopPattern::GEOFACTORY.point(-122.40182, 37.7067))
      stop_b.update_column(:geometry, RouteStopPattern::GEOFACTORY.point(-122.394935, 37.776348))
      stop_c.update_column(:geometry, RouteStopPattern::GEOFACTORY.point(-122.39, 37.84))
      expect(Geometry::DistanceCalculation.calculate_distances(@rsp)).to match_array([a_value_within(0.1).of(2.7),
                                                              a_value_within(0.1).of(7779.5),
                                                              a_value_within(0.1).of(14878.5)])
    end

    it 'accurately calculates distances if the first stop is not a before? stop, but not close enough to the line' do
      # consequently the first stop distance should be 0.0
      geom = Geometry::LineString.line_string([[-122.401811, 37.706675],[-122.394935, 37.776348],[-122.39, 37.84]])
      @rsp.geometry = geom
      stop_a.update_column(:geometry, RouteStopPattern::GEOFACTORY.point(-122.40182, 37.72))
      stop_b.update_column(:geometry, RouteStopPattern::GEOFACTORY.point(-122.394935, 37.776348))
      stop_c.update_column(:geometry, RouteStopPattern::GEOFACTORY.point(-122.39, 37.84))
      expect(Geometry::DistanceCalculation.calculate_distances(@rsp)).to match_array([a_value_within(0.1).of(0.0),
                                                              a_value_within(0.1).of(7779.5),
                                                              a_value_within(0.1).of(14878.5)])
    end

    it 'appropriately handles tricky case where 3rd stop would match to the first segment point' do
      feed, feed_version = load_feed(feed_version_name: :feed_version_sfmta_7385783, import_level: 1)
      expect(Issue.where(issue_type: 'distance_calculation_inaccurate').count).to eq 0
    end

    it 'can calculate distances for a closed loop shape where first and last stops are near each other' do
      feed, feed_version = load_feed(feed_version_name: :feed_version_grand_river_1426033, import_level: 1)
      expect(RouteStopPattern.first.stop_distances).to match_array([0.8,616.9,939.8,1381.0,1720.0,2001.1,2245.9,2512.0,2893.3,3387.2,3696.1,4020.1,4158.2,4534.9,5060.1,5354.3,5975.7,6496.3,7200.5,7361.4,7676.4,8228.6,8821.3,9169.3,9922.9,10116.2,10278.6,10650.2,11044.9,11170.4,11642.8,12021.2,12465.0,12796.4,13324.0,13557.6,13852.8,14470.1,14719.8,15156.2,15615.4,15754.6,16002.9,16451.2,16992.8,17266.0,17507.5,17783.6,18193.5,18394.9,18812.1,19063.5,19319.6,19500.8,19920.9,20517.5])
      expect(Issue.where(issue_type: 'distance_calculation_inaccurate').count).to eq 0
    end

    it 'calculates distances for real-world complex loop shapes' do
      feed, feed_version = load_feed(feed_version_name: :feed_version_marta, import_level: 1)
      expect(Issue.where(issue_type: 'distance_calculation_inaccurate').count).to eq 0
    end

    it 'handles case where first stop does not meet 25m threshold and would otherwise match to the end of the line' do
      feed, feed_version = load_feed(feed_version_name: :feed_version_hdpt_trip, import_level: 1)
      expect(RouteStopPattern.first.stop_distances).to match_array([91.2,357.2,811.5,1130.7,1716.7,1981.3,2909.3,3029.7,3364.5,3639.4,4179.9,6054.3,6506.2,6886.6,7440.9,7476.3,7968.8,8182.2,8433.0,8589.9,8709.7,8895.6,9444.7,9790.9,10485.9,11178.0,11963.4,12467.3,12733.2,13208.4,13518.9])
      expect(Issue.where(issue_type: 'distance_calculation_inaccurate').count).to eq 0
    end

    it 'calculates distances for line with segments having distances of 0.0 m' do
      feed, feed_version = load_feed(feed_version_name: :feed_version_pvta_trip, import_level: 1)
      expect(Issue.where(issue_type: 'distance_calculation_inaccurate').count).to eq 0
    end
  end

  context 'determining outlier stops' do
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

    it 'returns false when the stop is within 100 meters of the closest point on the line' do
      # distance is approx 81 m
      test_stop = create(:stop,
        onestop_id: "s-9q8yw8y448-test",
        geometry: Stop::GEOFACTORY.point(-122.3975, 37.741).to_s
      )
      @rsp.stop_pattern = [@sp[0],test_stop.onestop_id,@sp[1]]
      expect(Geometry::OutlierStop.outlier_stop(test_stop, @rsp)).to be false
    end

    it 'returns true when the stop is greater than 100 meters of the closest point on the line' do
      # distance is approx 146 m
      test_stop = create(:stop,
        onestop_id: "s-9q8yw8y448-test",
        geometry: Stop::GEOFACTORY.point(-122.3968, 37.7405).to_s
      )
      @rsp.stop_pattern = [@sp[0],test_stop.onestop_id,@sp[1]]
      expect(Geometry::OutlierStop.outlier_stop(test_stop, @rsp)).to be true
    end
  end
end
