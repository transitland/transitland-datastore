describe Geometry do

  def match_array_within(arr, e)
    match_array(arr.map{|v| a_value_within(e).of(v) })
  end

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
      i = locators.each_with_index.min_by{|loc,i| loc.distance_from_segment}[1]
      nearest_point = locators[i].interpolate_point(RGeo::Cartesian::Factory.new(srid: 4326))
      expect(Geometry::LineString.distance_along_line_to_nearest_point(cartesian_line, nearest_point, i)).to be_within(0.1).of(6508.84)
    end

    context '#shape_dist_traveled' do
      # NOTE: the given shape_dist_traveled may be different from any best match computed distance
      it '#shape_dist_traveled' do
        # this feed also contains duplicated shape points to test seg_index incrementing
        feed, feed_version = load_feed(feed_version_name: :feed_version_nj_path, import_level: 1)
        gtfs = GTFS::Source.build(feed_version.file.file.file)
        rsp = feed.imported_route_stop_patterns.first
        tl_stops = rsp.stop_pattern.map{ |stop_onestop_id| Stop.find_by_onestop_id!(stop_onestop_id) }
        # This uses a different approach than in GTFSGraph 1
        trip_ids = EntityImportedFromFeed.where(feed_version: feed_version, entity: rsp).distinct(:gtfs_id).pluck(:gtfs_id)
        trip = gtfs.trips.detect{|trip| trip.id == trip_ids.first}
        trip_stop_times = []
        gtfs.each_trip_stop_times(trip_ids=[trip.trip_id]){ |trip_id, stop_times| trip_stop_times = stop_times }
        expect(Geometry::GTFSShapeDistanceTraveled.gtfs_shape_dist_traveled(
          rsp,
          trip_stop_times,
          tl_stops,
          gtfs.shape_line(trip.shape_id).shape_dist_traveled
        )).to match_array([0.0, 1166.3, 2507.7, 4313.8])
      end


      it 'sets stop distance to the geometry length when stop_time\'s shape_dist_traveled is greater than the last shape point' do
        # the last stop time of trip 636342A5394B6507 is set to "3.0" in the GTFS, greater than "2.677" in shapes.txt
        feed, feed_version = load_feed(feed_version_name: :feed_version_nj_path_last_stop_past_edge, import_level: 1)
        expect(RouteStopPattern.first.stop_distances).to match_array([0.0, 1166.3, 2507.7, 4313.8])
        expect(RouteStopPattern.first[:geometry].length).to be_within(0.1).of(4313.8)
        expect(RouteStopPattern.last.stop_distances).to match_array([0.0, 1805.6, 3145.8, 4320.6])
        expect(RouteStopPattern.last[:geometry].length).to be_within(0.1).of(4320.6)
      end

      it 'sets stop distance to 0.0 when stop_time\'s shape_dist_traveled is less than the first shape point' do
        # the first shape point of trip 636342A5394B6507 is set to "0.10" while the first stop time dist is 0.0
        feed, feed_version = load_feed(feed_version_name: :feed_version_nj_path_first_stop_before_edge, import_level: 1)
        gtfs = GTFS::Source.build(feed_version.file.file.file)
        expect(RouteStopPattern.first.stop_distances).to match_array([0.0, 1166.3, 2507.7, 4313.8])
        expect(RouteStopPattern.last.stop_distances).to match_array([0.0, 1805.6, 3145.8, 4320.6])
      end


      it 'properly calculates distances when 2 stops match to same segment' do
        feed, feed_version = load_feed(feed_version_name: :feed_version_wmata_48587, import_level: 1)
        expect(RouteStopPattern.first.stop_distances).to match_array([0.0, 155.2, 863.5, 1794.1, 2913.2, 3187.8, 3733.7, 3918.1, 4762.5])
      end

      it 'discards shape_dist_traveled that results in distance issues' do
        # this complex trip comes with shape_dist_traveled but there are repeated dist values when there shouldn't be
        feed_cta, feed_version_cta = load_feed(feed_version_name: :feed_version_cta_476113351107, import_level: 1)
        expect(Issue.where(issue_type: 'distance_calculation_inaccurate').count).to eq 0
        expect(RouteStopPattern.first.geometry_source).to eq "shapes_txt"
      end
    end

    it 'no distance issues with RSPs generated from trip stop points' do
      feed, feed_version = load_feed(feed_version_name: :feed_version_seattle_childrens, import_level: 1)
      expect(RouteStopPattern.find_by_onestop_id!('r-c23p1-sch~gold-10c68e-2ef1dd').stop_distances).to match_array_within([0.0, 2070.3, 4140.7], 0.1)
      expect(Issue.where(issue_type: 'distance_calculation_inaccurate').size).to eq 0
    end

    it '#straight_line_distances' do
      expect(@rsp.stop_distances).to match_array([])
      @rsp.stop_distances = Geometry::DistanceCalculation.straight_line_distances(
        @rsp.stop_pattern.map{ |onestop_id| Stop.find_by_onestop_id!(onestop_id).geometry_centroid }
      )
      expect(@rsp.stop_distances).to match_array_within([0.0,12617.9,17001.5], 0.1)
    end

    it 'stores distances in stop_distances attribute' do
      Geometry::MetaDistances.new(@rsp).calculate_distances
      expect(@rsp.stop_distances.count).to eq 3
    end

    it 'can calculate distances when the geometry and stop coordinates are equal' do
      expect(Geometry::MetaDistances.new(@rsp).calculate_distances).to match_array_within([0.0,12617.9271,17001.5107], 0.1)
    end

    it 'can calculate distances when coordinates are repeated' do
      @feed, @feed_version = load_feed(feed_version_name: :feed_version_mtanyctbusstatenisland_trip_YU_S6_Weekday_030000_MISC_112, import_level: 1)
      distances = Geometry::MetaDistances.new(@feed.imported_route_stop_patterns[0]).calculate_distances
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
      expect(Geometry::MetaDistances.new(@rsp).calculate_distances).to match_array_within([0.0,12617.9271,14809.7189,17001.5107], 0.1)
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
      expect(Geometry::MetaDistances.new(@rsp).calculate_distances).to match_array([a_value_within(0.1).of(0.0),
                                                              a_value_within(0.1).of(12617.9271),
                                                              a_value_within(0.5).of(14809.7189),
                                                              a_value_within(0.1).of(17001.5107)])
    end

    it 'accurately calculates the distances of nyc staten island ferry 2-stop routes with before/after stops' do
      @feed, @feed_version = load_feed(feed_version_name: :feed_version_nycdotsiferry, import_level: 1)
      expect(Geometry::MetaDistances.new(@feed.imported_route_stop_patterns[0]).calculate_distances).to match_array([0.0, 8138.0])
      expect(Geometry::MetaDistances.new(@feed.imported_route_stop_patterns[1]).calculate_distances).to match_array([3.2, 8141.2])
    end

    it 'accurately calculates the distances of a route with stops along the line that traversed over itself in the opposite direction' do
      # see https://transit.land/documentation/datastore/rome_01_part_1.png
      # and https://transit.land/documentation/datastore/rome_01_part_2.png
      @feed, @feed_version = load_feed(feed_version_name: :feed_version_rome, import_level: 1)
      expect(Geometry::MetaDistances.new(@feed.imported_route_stop_patterns[0]).calculate_distances).to match_array([0.6,639.6,817.5,1034.9,1250.2,1424.2,1793.5,1929.2,2162.2,2429.9,2579.6,2735.3,3022.6,3217.8,3407.3,3646.6,3804.4,3969.1,4128.3,4302.6,4482.1,4586.9,4869.5,5242.7,5510.4,5695.6,5871.4,6112.9,6269.6,6334.1,6528.8,6715.4,6863.0,7140.2,7689.8])
    end

    it 'accurately calculates the distances of a route with stops along the line that traversed over itself in the opposite direction, but closest match was segment in opposite direction' do
      @feed, @feed_version = load_feed(feed_version_name: :feed_version_vta_1965654, import_level: 1)
      expect(Geometry::MetaDistances.new(@feed.imported_route_stop_patterns[0]).calculate_distances).to match_array([0.0,1490.8,1818.6,2478.0,2928.5,3167.2,3584.7,4079.4,4360.6,4784.1,4970.5,5168.1,5340.5,5599.0,6023.2,6483.9,6770.0,7469.3])
    end

    it 'calculates the first stop distance correctly' do
      # from sfmta route 54 and for regression. case where first stop is not a 'before' stop
      # see https://transit.land/documentation/datastore/first_stop_correct_distance.png
      @feed, @feed_version = load_feed(feed_version_name: :feed_version_sfmta_6720619, import_level: 1)
      distances = Geometry::MetaDistances.new(@feed.imported_route_stop_patterns[0]).calculate_distances
      expect(distances[0]).to be_within(0.1).of(201.1)
    end

    it 'can accurately calculate distances when a stop is repeated.' do
      # from f-9q9-vta, r-9q9k-66.
      # see https://transit.land/documentation/datastore/repeated_stop_vta_66.png
      @feed, @feed_version = load_feed(feed_version_name: :feed_version_vta_1930705, import_level: 1)
      distances = Geometry::MetaDistances.new(@feed.imported_route_stop_patterns[0]).calculate_distances
      expect(distances[77]).to be > distances[75]
    end

    it 'can accurately calculate distances when a stop matches to a segment before the previous stop\'s matching segment' do
      # from sfmta, N-OWL route.
      # See https://transit.land/documentation/datastore/previous_segment_1_sfmta_n~owl.png
      # and https://transit.land/documentation/datastore/previous_segment_2_sfmta_n~owl.png
      @feed, @feed_version = load_feed(feed_version_name: :feed_version_sfmta_6731593, import_level: 1)
      tricky_rsp = @feed.imported_route_stop_patterns[0]
      distances = Geometry::MetaDistances.new(tricky_rsp).calculate_distances
      expect(distances[-1]).to be > distances[-2]
    end

    it 'calculates the distance of the first stop to be 0 if it is before the first point of a geometry' do
      @rsp.stop_pattern = @rsp.stop_pattern.unshift(create(:stop,
        onestop_id: "s-9q9hwp6epk-before~geometry",
        geometry: Stop::GEOFACTORY.point(-121.5, 37.30).to_s
      ).onestop_id)
      expect(Geometry::MetaDistances.new(@rsp).calculate_distances).to match_array_within([0.0,0.0,12617.9,17001.5], 0.1)
    end

    it 'calculates the distance of the last stop to be the length of the line geometry if it is after the last point of the geometry' do
      @rsp.stop_pattern << create(:stop,
       onestop_id: "s-9q9hwp6epk-after~geometry",
       geometry: Stop::GEOFACTORY.point(-122.1, 37.41).to_s
      ).onestop_id
      @rsp.geometry = Geometry::LineString.line_string(@rsp.geometry[:coordinates] << [-122.09, 37.401])
      distances = Geometry::MetaDistances.new(@rsp).calculate_distances
      expect(distances[3]).to be_within(0.1).of(@rsp[:geometry].length)
      expect(distances).to match_array_within([0.0,12617.9,17001.5,18447.4], 0.1)
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
      expect(Geometry::MetaDistances.new(@rsp).calculate_distances).to match_array_within([0.0,12617.9271,14809.7,17001.5107], 0.1)
    end

    it 'assign a fallback distance value equal to the geometry length to the last stop if it is an outlier' do
      last_stop_outlier = create(:stop,
        onestop_id: "s-9q9hwtgq4s-last~outlier",
        geometry: Stop::GEOFACTORY.point(-121.5, 37.3).to_s
      )
      @rsp.stop_pattern << last_stop_outlier.onestop_id
      expect(Geometry::MetaDistances.new(@rsp).calculate_distances).to match_array_within([0.0,12617.9271,17001.5107,17001.5107], 0.1)
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
      expect(Geometry::MetaDistances.new(@rsp).calculate_distances).to match_array_within([0.0,12617.9271,12617.9271,17001.5107], 0.1)
    end

    it 'can readjust distances when stops match to the same segment out of order' do
      @feed, @feed_version = load_feed(feed_version_name: :feed_version_sfmta_7310245, import_level: 1)
      distances = Geometry::MetaDistances.new(@feed.imported_route_stop_patterns[0]).calculate_distances
      # expect all distances to be increasing
      expect(distances[1..-1].each_with_index.map { |v, i| v > distances[i] }.all?).to be true
    end

    it 'accurately calculates distances if the last stop is an after? stop' do
      geom = Geometry::LineString.line_string([[-122.41, 37.65],[-122.401811, 37.706675],[-122.394935, 37.776348]])
      @rsp.geometry = geom
      stop_a.update_column(:geometry, RouteStopPattern::GEOFACTORY.point(-122.41, 37.65))
      stop_b.update_column(:geometry, RouteStopPattern::GEOFACTORY.point(-122.401811, 37.706675))
      stop_c.update_column(:geometry, RouteStopPattern::GEOFACTORY.point(-122.38, 37.78))
      expect(Geometry::MetaDistances.new(@rsp).calculate_distances).to match_array_within([0.0,6350.2,14129.7], 0.1)
    end

    it 'accurately calculates distances if the last stop is close to the line and is not an after? stop' do
      geom = Geometry::LineString.line_string([[-122.41, 37.65],[-122.401811, 37.706675],[-122.394935, 37.776348]])
      @rsp.geometry = geom
      stop_a.update_column(:geometry, RouteStopPattern::GEOFACTORY.point(-122.41, 37.65))
      stop_b.update_column(:geometry, RouteStopPattern::GEOFACTORY.point(-122.401811, 37.706675))
      stop_c.update_column(:geometry, RouteStopPattern::GEOFACTORY.point(-122.3975, 37.741))
      expect(Geometry::MetaDistances.new(@rsp).calculate_distances).to match_array_within([0.0,6350.2,10192.9], 0.1)
    end

    it 'assigns the length of the geometry to the last stop distance when the last and penultimate are out of order' do
      feed, feed_version = load_feed(feed_version_name: :feed_version_ttc_34360409, import_level: 1)
      rsp = RouteStopPattern.first
      # set the penultimate stop coordinate to the last point of the line
      Stop.find_by_onestop_id!(rsp.stop_pattern[rsp.stop_pattern.size - 2]).update_column(:geometry, Stop::GEOFACTORY.point(*rsp[:geometry].coordinates.last))
      expect(Geometry::MetaDistances.new(rsp).calculate_distances[rsp.stop_pattern.size-2..rsp.stop_pattern.size-1]).to eq [950.0, 950.0]
    end

    it 'sets the last stop distance to the length of the line geometry if it is > 100m from the line and less than distance of previous stop' do
      feed, feed_version = load_feed(feed_version_name: :feed_version_ttc_34360409, import_level: 1)
      rsp = RouteStopPattern.first
      # set the penultimate stop coordinate to be near the last coordinate
      Stop.find_by_onestop_id!(rsp.stop_pattern[rsp.stop_pattern.size - 2]).update_column(:geometry, Stop::GEOFACTORY.point(-79.53941, 43.7388))
      # moving the last stop to be an outlier, but with a distance less than the previous stop
      Stop.find_by_onestop_id!(rsp.stop_pattern[-1]).update_column(:geometry, Stop::GEOFACTORY.point(-79.535, 43.73898))
      expect(Geometry::MetaDistances.new(rsp).calculate_distances[rsp.stop_pattern.size-2..rsp.stop_pattern.size-1]).to eq [929.9, 950.0]
    end

    it 'accurately calculates distances if the first stop is a before? stop' do
      geom = Geometry::LineString.line_string([[-122.401811, 37.706675],[-122.394935, 37.776348],[-122.39, 37.84]])
      @rsp.geometry = geom
      stop_a.update_column(:geometry, RouteStopPattern::GEOFACTORY.point(-122.41, 37.69))
      stop_b.update_column(:geometry, RouteStopPattern::GEOFACTORY.point(-122.394935, 37.776348))
      stop_c.update_column(:geometry, RouteStopPattern::GEOFACTORY.point(-122.39, 37.84))
      expect(Geometry::MetaDistances.new(@rsp).calculate_distances).to match_array_within([0.0,7779.5,14878.5], 0.1)
    end

    it 'accurately calculates distances if the first stop is close to the line and not a before? stop' do
      geom = Geometry::LineString.line_string([[-122.401811, 37.706675],[-122.394935, 37.776348],[-122.39, 37.84]])
      @rsp.geometry = geom
      stop_a.update_column(:geometry, RouteStopPattern::GEOFACTORY.point(-122.40182, 37.7067))
      stop_b.update_column(:geometry, RouteStopPattern::GEOFACTORY.point(-122.394935, 37.776348))
      stop_c.update_column(:geometry, RouteStopPattern::GEOFACTORY.point(-122.39, 37.84))
      expect(Geometry::MetaDistances.new(@rsp).calculate_distances).to match_array_within([2.7,7779.5,14878.5], 0.1)
    end

    it 'accurately calculates distances if the first stop is an outlier stop, but matches to line before second stop' do
      # in essence, the first stop can a "before?" stop, but can match to the inside of a line.
      feed_cta, feed_version_cta = load_feed(feed_version_name: :feed_version_cta_476113351107, import_level: 1)
      feed_trenitalia, feed_version_trenitalia = load_feed(feed_version_name: :feed_version_trenitalia_56808573, import_level: 1)
      expect(Geometry::MetaDistances.new(feed_cta.imported_route_stop_patterns.first).calculate_distances[0..1]).to match_array([0.0,29.8])
      expect(Geometry::MetaDistances.new(feed_trenitalia.imported_route_stop_patterns.first).calculate_distances[0..1]).to match_array([6547.6, 8079.6])
    end

    it 'appropriately handles tricky case where 3rd stop would match to the first segment point' do
      feed, feed_version = load_feed(feed_version_name: :feed_version_sfmta_7385783, import_level: 1)
      expect(Issue.where(issue_type: 'distance_calculation_inaccurate').count).to eq 0
    end

    it 'calculates distances for case when second stop is close to first segment, but there is a loop between first and second stop' do
      feed, feed_version = load_feed(feed_version_name: :feed_version_mbta_33884627, import_level: 1)
      expect(RouteStopPattern.first.stop_distances[1]).to eq 327.5
    end

    it 'can calculate distances for a closed loop shape where first and last stops are near each other' do
      feed, feed_version = load_feed(feed_version_name: :feed_version_grand_river_1426033, import_level: 1)
      expect(RouteStopPattern.first.stop_distances).to match_array([0.8,617.8,939.8,1381.0,1720.3,2000.4,2248.0,2515.1,2894.5,3387.2,3696.6,4018.7,4156.4,4534.9,5060.1,5357.4,5977.3,6496.3,7200.5,7362.6,7678.2,8230.4,8818.6,9169.3,9921.2,10113.3,10278.6,10650.2,11044.9,11172.1,11644.4,12022.2,12465.0,12798.3,13324.0,13557.6,13854.5,14470.1,14717.5,15156.8,15615.4,15754.6,16004.2,16451.2,16992.8,17267.9,17507.5,17783.6,18193.5,18394.9,18809.7,19061.2,19319.6,19500.8,19920.9,20517.5])
      expect(Issue.where(issue_type: 'distance_calculation_inaccurate').count).to eq 0
    end

    it 'calculates distances for real-world complex loop shapes' do
      feed, feed_version = load_feed(feed_version_name: :feed_version_marta, import_level: 1)
      expect(Issue.where(issue_type: 'distance_calculation_inaccurate').count).to eq 0
    end

    it 'handles case where first stop is not close to the line except towards the end' do
      feed, feed_version = load_feed(feed_version_name: :feed_version_hdpt_shop_trip, import_level: 1)
      expect(RouteStopPattern.first.stop_distances).to match_array([91.2,357.2,811.5,1130.7,1716.7,1981.3,2909.3,3029.7,3364.5,3639.4,4179.9,6054.3,6506.2,6886.6,7413.8,7435.3,7968.8,8182.2,8433.0,8589.9,8709.7,8895.6,9444.7,9790.9,10485.9,11178.0,11963.4,12467.3,12733.2,13208.4,13518.9])
      expect(Issue.where(issue_type: 'distance_calculation_inaccurate').count).to eq 0
    end

    it 'handles case of stop slightly out of order with previous, and identical matching segments. readjusts distances.' do
      feed, feed_version = load_feed(feed_version_name: :feed_version_hdpt_sun_trip, import_level: 1)
      expect(RouteStopPattern.first.stop_distances).to match_array([35.9,295.3,747.8,1061.6,1652.3,1946.8,4168.1,4616.7,4994.4,5533.2,5542.4,6063.4,6282.9,6524.0,6682.7,6775.9,6961.1,7505.6,8912.2,9572.1,10265.7,11055.5,11547.6,11822.3,12294.7,12653.7,13071.7,13371.8,13862.3,14025.0,14184.7,15050.8,15923.9,16247.5,16636.5])
      expect(Issue.where(issue_type: 'distance_calculation_inaccurate').count).to eq 0
    end

    it 'calculates distances for line with segments having distances of 0.0 m' do
      feed, feed_version = load_feed(feed_version_name: :feed_version_pvta_trip, import_level: 1)
      expect(Issue.where(issue_type: 'distance_calculation_inaccurate').count).to eq 0
    end

    it 'handles short, straight-line, reverse loop' do
      feed, feed_version = load_feed(feed_version_name: :feed_version_marta_trip_5449755, import_level: 1)
      expect(Issue.where(issue_type: 'distance_calculation_inaccurate').count).to eq 0
    end

    it 'handles alleghany stop distances' do
      # Complex RSP shape revisits set of stops whose closest match is on second visit
      feed, feed_version = load_feed(feed_version_name: :feed_version_alleghany, import_level: 1)

      # Algorithm has minor discrepancy with optimal value.
      expect(RouteStopPattern.first.stop_distances).to match_array([0.0, 1564.3, 2948.4, 7916.3, 15691.7, 21963.3, 28515.8, 34874.6, 35537.6, a_value_within(2.0).of(37510.9), 38152.8, 39011.8, 40017.6, 41943.4, 51008.5, 57260.7, 64464.1, 70759.1])
    end

    xit 'attempts a readjustment if stops are out of order' do
      feed, feed_version = load_feed(feed_version_name: :feed_version_ttc_34398377, import_level: 1)
      expect(Geometry::MetaDistances.new(RouteStopPattern.first).calculate_distances[0..1]).to match_array([40.0, 52.4])
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
      expect(Geometry::OutlierStop.new(test_stop, @rsp).outlier_stop?).to be false
    end

    it 'returns true when the stop is greater than 100 meters of the closest point on the line' do
      # distance is approx 146 m
      test_stop = create(:stop,
        onestop_id: "s-9q8yw8y448-test",
        geometry: Stop::GEOFACTORY.point(-122.3968, 37.7405).to_s
      )
      @rsp.stop_pattern = [@sp[0],test_stop.onestop_id,@sp[1]]
      expect(Geometry::OutlierStop.new(test_stop, @rsp).outlier_stop?).to be true
    end
  end
end
