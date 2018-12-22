describe FeedEaterService do
  context 'example feed' do
    before(:all) {
      @feed, @feed_version = load_feed(feed_version_name: :feed_version_example, import_level: 2)
    }
    after(:all) {
      DatabaseCleaner.clean_with :truncation, { except: ['spatial_ref_sys'] }
    }

    it 'updated feed geometry' do
      expect_coords = [[
        [-117.133162, 36.425288],
        [-116.40094, 36.425288],
        [-116.40094, 36.915682],
        [-117.133162, 36.915682],
        [-117.133162, 36.425288]]
      ]
      feed_coords = @feed.geometry(as: :geojson)[:coordinates]
      expect_coords.first.zip(feed_coords.first).each { |a,b|
        expect(a[0]).to be_within(0.001).of(b[0])
        expect(a[1]).to be_within(0.001).of(b[1])
      }
    end

    it 'created a known Operator' do
      expect(@feed.imported_operators.count).to eq(1)
      expect(@feed_version.imported_operators).to eq(@feed.imported_operators)
      o = @feed.operators.find_by_onestop_id('o-9qs-demotransitauthority')
      expect(o).to be_truthy
      expect(o.name).to eq('Demo Transit Authority')
      expect(o.onestop_id).to eq('o-9qs-demotransitauthority')
      expect(o.geometry).to be
      expect(o.timezone).to eq('America/Los_Angeles')
      expect(o.website).to eq('http://www.google.com')
    end

    it 'created known Routes' do
      expect(@feed.imported_routes.count).to eq(5)
      expect(@feed_version.imported_routes).to eq(@feed.imported_routes)
      r = @feed.imported_routes.find_by_onestop_id!('r-9qscy-10')
      expect(r).to be_truthy
      expect(r.name).to eq('10')
      expect(r.onestop_id).to eq('r-9qscy-10')
      expect(r.vehicle_type).to eq(:bus)
      expect(r.vehicle_type_value).to eq(3)
      expect(r.tags['route_long_name']).to eq('Airport - Bullfrog')
      expect(r.geometry).to be
      expect(r.wheelchair_accessible).to eq('unknown')
    end

    it 'created known Stops' do
      expect(@feed.imported_stops.count).to eq(9)
      expect(@feed_version.imported_stops).to eq(@feed.imported_stops)
      s = @feed.imported_stops.find_by_onestop_id!('s-9qscwx8n60-nyecountyairportdemo')
      expect(s).to be_truthy
      expect(s.name).to eq('Nye County Airport (Demo)')
      expect(s.onestop_id).to eq('s-9qscwx8n60-nyecountyairportdemo')
      expect(s.geometry).to be
      expect(s.timezone).to eq('America/Los_Angeles')
    end

    it 'created known RouteStopPatterns' do
      expect(@feed.imported_route_stop_patterns.count).to eq(9)
    end

    it 'created known Route that traverses known Route Stop Patterns' do
      r = @feed.imported_routes.find_by_onestop_id!('r-9qscy-10')
      expect(r.route_stop_patterns.size).to eq(2)
      expect(r.route_stop_patterns.map(&:onestop_id)).to contain_exactly(
          "r-9qscy-10-5dca2b-ae2f1e",
          "r-9qscy-10-1b7e7d-bc0214"
      )
    end

    it 'calculated and stored distances for Route Stop Patterns' do
      rsp = @feed.imported_route_stop_patterns.find_by_onestop_id!('r-9qsczp-40-0830a7-0da42c')
      expect(rsp.stop_distances).to match_array(
        [0.0, 685.1, 1286.7, 1886.4, 2762.0].map{ |value| be_within(2.0).of(value) }
      )
    end

    it 'created known Operator that serves known Routes' do
      o = @feed.imported_operators.find_by_onestop_id!('o-9qs-demotransitauthority')
      expect(o.routes.size).to eq(5)
      expect(o.routes.map(&:onestop_id)).to contain_exactly(
        "r-9qsb-20",
        "r-9qscy-10",
        "r-9qscy-30",
        "r-9qsczp-40",
        "r-9qt1-50"
      )
    end

    it 'created known Operator that serves known Stops' do
      o = @feed.imported_operators.find_by_onestop_id!('o-9qs-demotransitauthority')
      # Just check the number of stops here...
      expect(o.stops.count).to eq(9)
    end

    it 'created known Routes that serve known Stops' do
      r = @feed.imported_routes.find_by_onestop_id!('r-9qsczp-40')
      expect(r.stops.size).to eq(5)
      expect(r.stops.map(&:onestop_id)).to match_array([
        "s-9qsfp2212t-stagecoachhotel~casinodemo",
        "s-9qsfp00vhs-northave~naavedemo",
        "s-9qsfnb5uz6-northave~davendemo",
        "s-9qscyz5vqg-doingave~davendemo",
        "s-9qsczn2rk0-emainst~sirvingstdemo"
      ])
    end

    it 'created known ScheduleStopPairs' do
      expect(@feed.imported_schedule_stop_pairs.count).to eq(49) # EXACTLY.
      expect(@feed_version.imported_schedule_stop_pairs.pluck(:id)).to match_array(@feed.imported_schedule_stop_pairs.pluck(:id))
      # Find a UNIQUE SSP, by origin, destination, route, trip.
      origin = @feed.imported_stops.find_by!(
        onestop_id: "s-9qsfp2212t-stagecoachhotel~casinodemo"
      )
      destination = @feed.imported_stops.find_by!(
        onestop_id: "s-9qsfp00vhs-northave~naavedemo"
      )
      route = @feed.imported_routes.find_by!(onestop_id: 'r-9qsczp-40')
      route_stop_pattern = @feed.imported_route_stop_patterns.find_by!(onestop_id: 'r-9qsczp-40-1f22a1-3d01d2')
      operator = @feed.operators.find_by(onestop_id: 'o-9qs-demotransitauthority')
      trip = 'CITY1'
      found = @feed.imported_schedule_stop_pairs.where(
        origin: origin,
        destination: destination,
        route: route,
      ).order(id: :asc)
      expect(found.count).to eq(5)
      s = found.first
      expect(s).to be_truthy
      expect(s.origin).to eq(origin)
      expect(s.destination).to eq(destination)
      expect(s.route).to eq(route)
      expect(s.route_stop_pattern).to eq(route_stop_pattern)
      expect(s.operator).to eq(operator)
      expect(s.trip).to eq(trip)
      expect(s.trip_headsign).to eq("E Main St / S Irving St (Demo)")
      expect(s.trip_short_name).to be nil
      expect(s.origin_timezone).to eq('America/Los_Angeles')
      expect(s.destination_timezone).to eq('America/Los_Angeles')
      expect(s.shape_dist_traveled).to eq(0.0)
      expect(s.block_id).to eq(nil)
      expect(s.wheelchair_accessible).to eq(nil)
      expect(s.bikes_allowed).to eq(nil)
      expect(s.pickup_type).to eq(nil)
      expect(s.drop_off_type).to eq(nil)
      expect(s.origin_arrival_time).to eq('06:00:00')
      expect(s.origin_departure_time).to eq('06:00:00')
      expect(s.destination_arrival_time).to eq('06:05:00')
      expect(s.destination_departure_time).to eq('06:07:00')
      expect(s.origin_dist_traveled).to eq 0.0
      expect(s.destination_dist_traveled).to be_within(0.5).of(875.4)
      expect(s.service_days_of_week).to match_array(
        [true, true, true, true, true, true, true]
      )
      expect(s.service_added_dates.map(&:to_s)).to contain_exactly()
      expect(s.service_except_dates.map(&:to_s)).to contain_exactly("2007-06-04")
      expect(s.service_start_date.to_s).to eq('2007-01-01')
      expect(s.service_end_date.to_s).to eq('2010-12-31')
      expect(s.origin_timepoint_source).to eq('gtfs_exact')
      expect(s.destination_timepoint_source).to eq('gtfs_exact')
      expect(s.window_start).to eq('06:00:00')
      expect(s.window_end).to eq('06:05:00')
      expect(s.frequency_start_time).to eq('06:00:00')
      expect(s.frequency_end_time).to eq('07:59:59')
      expect(s.frequency_headway_seconds).to eq(1800)
      expect(s.frequency_type).to eq('not_exact')
    end

    it 'uses times relative to frequency_start_time' do
      ssps = ScheduleStopPair.where(
        route: Route.find_by_onestop_id!('r-9qsczp-40'),
        trip: 'CITY1',
        frequency_start_time: '08:00:00',
        frequency_end_time: '09:59:59'
      ).order(origin_arrival_time: :asc)
      expect(ssps.first.origin_arrival_time).to eq('08:00:00')
      expect(ssps.first.origin_departure_time).to eq('08:00:00')
      expect(ssps.second.origin_arrival_time).to eq('08:05:00')
      expect(ssps.second.origin_departure_time).to eq('08:07:00')
    end
  end

  context 'operators_in_feed' do
    it 'copies operators_in_feed to FeedVersionImport' do
      feed_version = create(:feed_version_example)
      oif_feed = feed_version.feed.operators_in_feed.map{ |i| {'gtfs_agency_id'=>i.gtfs_agency_id, 'feed_id'=>i.feed_id, 'feed_onestop_id'=>i.feed.onestop_id, 'operator_id'=>i.operator_id, 'operator_onestop_id'=>i.operator.onestop_id} }
      load_feed(feed_version: feed_version, import_level: 1)
      oif_fvi = feed_version.feed_version_imports.last.operators_in_feed
      expect(oif_feed).to eq(oif_fvi)
    end
  end

  context 'feed transition' do
    before(:each) {
      @feed, @original_feed_version = load_feed(feed_version_name: :feed_version_example, import_level: 1)
      @feed_version_update_add = create(:feed_version_example_update_add, feed: @feed)
      @feed_version_update_delete = create(:feed_version_example_update_delete, feed: @feed)
    }

    it 'creates a new tl entity not found in previous feed version' do
      expect(@feed.imported_stops.size).to eq 9
      expect(@feed.imported_routes.size).to eq 5
      expect(@feed.imported_routes.find_by_onestop_id('r-9qscy-60')).to be_falsey
      load_feed(feed_version: @feed_version_update_add, import_level: 1)
      expect(@feed.imported_stops.size).to eq 10
      expect(@feed.imported_routes.size).to eq 6
      expect(@feed.imported_routes.find_by_onestop_id('r-9qscy-60')).to be_truthy
      expect(@feed.imported_stops.find_by_onestop_id('s-9qt1hbwder-newstop')).to be_truthy
    end

    it 'does not delete a previous feed version entity' do
      expect(@feed.imported_stops.size).to eq 9
      expect(@feed.imported_routes.size).to eq 5
      expect(@feed.imported_routes.find_by_onestop_id('r-9qscy-10')).to be_truthy
      load_feed(feed_version: @feed_version_update_delete, import_level: 1)
      expect(@original_feed_version.imported_routes.find_by_onestop_id('r-9qscy-10')).to be_truthy
      expect(@feed_version_update_delete.imported_routes.find_by_onestop_id('r-9qscy-10')).to be_falsey
      expect(@feed_version_update_delete.imported_stops.find_by_onestop_id('s-9qsczn2rk0-emainst~sirvingstdemo')).to be_falsey
      expect(@feed.imported_stops.size).to eq 9
      expect(@feed.imported_routes.size).to eq 6
    end

    it 'updates previous matching feed version entities with new attribute values' do
      expect(@feed.imported_routes.find_by_onestop_id('r-9qscy-10').vehicle_type).to eq 'bus'
      load_feed(feed_version: @feed_version_update_add, import_level: 1)
      expect(@feed.imported_routes.find_by_onestop_id('r-9qscy-10').vehicle_type).to eq 'rail'
    end

    it 'does not modify previous matching feed version entities unchangeable attributes' do
      original_creation_time = @feed.imported_stops.find_by_onestop_id('s-9qscv9zzb5-bullfrogdemo').created_at
      load_feed(feed_version: @feed_version_update_add, import_level: 1)
      expect(@feed_version_update_add.imported_stops.find_by_onestop_id('s-9qscv9zzb5-bullfrogdemo').created_at).to eq original_creation_time
    end

    it 'matches previous stop_id' do
      osid = "s-9qscwx8n60-nyecountyairportdemo"
      osid_new = 's-9qscwx8n60-test'
      s = Stop.find_by_onestop_id!(osid)
      s.update!(onestop_id: osid_new)
      # Import again
      load_feed(feed_version: @feed_version_update_add, import_level: 1)
      expect(s.reload.entities_imported_from_feed.count).to eq(2)
    end

    it 'destroys old RSPs, but not edited ones' do
      rsp = create(:route_stop_pattern)
      edited_rsp = create(:route_stop_pattern, edited_attributes: ["geometry"])
      @original_feed_version.entities_imported_from_feed.create!(feed: @feed, entity: rsp)
      load_feed(feed_version: @original_feed_version, import_level: 1)
      expect(RouteStopPattern.exists?(rsp.id)).to be_falsey
      expect(RouteStopPattern.exists?(edited_rsp.id)).to be_truthy
    end
  end

  context 'station hierarchy' do
    before(:all) {
      @feed, @feed_version = load_feed(feed_version_name: :feed_version_example_station, import_level: 2)
    }
    after(:all) {
      DatabaseCleaner.clean_with :truncation, { except: ['spatial_ref_sys'] }
    }

    it 'contains a station with 1 platform' do
      s = Stop.find_by_onestop_id!('s-9qt0rnrkjt-station1')
      expect(s.stop_platforms.count).to eq(1)
      expect(s.stop_platforms.first.onestop_id).to eq('s-9qt0rnrkjt-station1<station1p1')
    end

    it 'contains a station with 1 egress' do
      s = Stop.find_by_onestop_id!('s-9qt0rnrkjt-station1')
      expect(s.stop_egresses.count).to eq(1)
      expect(s.stop_egresses.first.onestop_id).to eq('s-9qt0rnrkjt-station1>station1e1')
    end

    it 'SSPs do not begin or end at Egresses' do
      origins = ScheduleStopPair.where('').pluck(:origin_id)
      destinations = ScheduleStopPair.where('').pluck(:destination_id)
      egresses = StopEgress.where('').pluck(:id)
      expect(origins & egresses).to eq([])
      expect(destinations & egresses).to eq([])
    end
  end

  context 'errors' do
    it 'fails and logs payload errors' do
      allow_any_instance_of(ChangePayload).to receive(:payload_validation_errors).and_return([{message: 'payload validation error'}])
      feed_version = create(:feed_version_example)
      feed = feed_version.feed
      graph = GTFSGraphImporter.new(feed, feed_version)
      expect {
        graph.create_change_osr
      }.to raise_error(Changeset::Error)
      expect(graph.import_log.include?('payload validation error')).to be_truthy
    end

    it 'fails if no matching operator_in_feed' do
      feed_version = create(:feed_version_example)
      feed = feed_version.feed
      oif = feed.operators_in_feed.first
      oif.update!({gtfs_agency_id:'not-found'})
      graph = GTFSGraphImporter.new(feed, feed_version)
      expect { graph.create_change_osr }.to raise_error(GTFSGraphImporter::Error)
      issue = Issue.last
      expect(issue.issue_type).to eq(:feed_import_no_operators_found)
      expect(issue.entities_with_issues.map(&:entity)).to match_array([feed_version])
    end
  end

  context 'sticky and edited attributes' do
    before(:each) {
      @create_fv_import = Proc.new { |graph| graph.feed_version.feed_version_imports.create!( import_level: 1) }
      @feed, @original_feed_version = load_feed(feed_version_name: :feed_version_example, import_level: 1, block_before_level_1: @create_fv_import)
    }

    it 'allows data from the first feed version import to be saved' do
      # assumes :name is a sticky attribute, and is required to be not nil on the model
      # fail if :name is not sticky so it can be adjusted to something else
      expect(Stop.sticky_attributes.map(&:to_sym)).to include(:name)
      expect(Stop.first.name).to be
    end

    it 'prevents subsequent feed version imports from modifying edited and sticky attributes' do
      # assuming name is a sticky attribute
      non_import_changeset = create(:changeset, payload: {
        changes: [
          {
            action: 'createUpdate',
            stop: {
              onestopId: 's-9qscwx8n60-nyecountyairportdemo',
              name: 'Edited Stop Name',
              timezone: 'America/Los_Angeles'
            }
          }
        ]
      })
      non_import_changeset.apply!
      @feed_version_update_add = create(:feed_version_example_update_add, feed: @feed)
      load_feed(feed_version: @feed_version_update_add, import_level: 1, block_before_level_1: @create_fv_import)
      expect(Stop.find_by_onestop_id!('s-9qscwx8n60-nyecountyairportdemo').name).to eq "Edited Stop Name"
    end
  end

  context 'special checks' do
    it 'skipped RouteStopPattern generation with trips having less than 2 stop times' do
      feed, feed_version = load_feed(feed_version_name: :feed_version_example_trips_special_stop_times, import_level: 1)
      # 'BFC2' is a 1 stop time trip; 'BFC1' has no stop times
      expect(feed.imported_route_stop_patterns.size).to eq 8
    end

    it 'does not use RSP EIFFs' do
      # Before fix, RSPs can become mismatched with Routes:
      #   rsp.route.onestop_id: r-9q9-test
      #   BFC1 is a trip_id for Route BFC / r-9qsb-20
      #   import
      #     -> rsp.onestop_id: r-9q9-test-5dca2b-ae2f1e
      #     -> rsp.route.onestop_id: r-9qsb-20 # prefix mismatch!
      # After fix:
      #   RSPs are not re-used via EIFF
      #   import
      #     -> rsp is deleted because it is no longer referenced.
      feed_version = create(:feed_version_example)
      feed = feed_version.feed
      feed.update!(active_feed_version: feed_version)
      route = create(:route, onestop_id: "r-9q9-test")
      rsp = create(:route_stop_pattern, route: route)
      rsp.update!(onestop_id: "r-9q9-test-5dca2b-ae2f1e")
      rsp.entities_imported_from_feed.create!(gtfs_id: "BFC1", feed: feed, feed_version: feed_version)
      feed, feed_version = load_feed(feed_version: feed_version, import_level: 1)
      expect { rsp.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'allows multiple agency_ids to point to single Operator' do
      # In this feed, Route "r-9qt1-50" is associated with agency_id "DTA2"
      # where both "DTA" and "DTA2" point to "o-9qs-demotransitauthority"
      feed, feed_version = load_feed(feed_version_name: :feed_version_example_multiple_agency_id_same_operator, import_level: 1)
      operator = feed.imported_operators.find_by_onestop_id!("o-9qs-demotransitauthority")
      expect(operator.routes.find_by_onestop_id!("r-9qt1-50")).to be_truthy
    end

    it 'ignores missing routes' do
      # Delete a route & rsp before SSPs are processed ->
      #     expect SSPs for this route & rsp trips to be skipped
      block_before_level_2 = Proc.new { |graph|
        Route.find_by_onestop_id!('r-9qsb-20').delete
        RouteStopPattern.find_by_onestop_id!('r-9qt1-50-5cba7c-25211f').delete
      }
      feed, feed_version = load_feed(feed_version_name: :feed_version_example, import_level: 2, block_before_level_2: block_before_level_2)
      expect(feed.imported_schedule_stop_pairs.count).to eq(45) # WAS 17
      expect(feed.imported_schedule_stop_pairs.where(route: Route.find_by_onestop_id('r-9qt1-50')).count).to eq(2) # WAS 4
    end

    it 'headsign: fall back to trip_headsign and last stop name' do
      # Mock GTFS::StopTime return stop_headsign "AAMV1 Test" for trip "AAMV1"
      allow_any_instance_of(GTFS::StopTime).to receive(:stop_headsign) do |stoptime|
        if stoptime.trip_id == 'AAMV1'
          'AAMV1 Test'
        else
          stoptime.instance_variable_get('@stop_headsign')
        end
      end
      # Import
      feed, feed_version = load_feed(feed_version_name: :feed_version_example_trips_special_stop_times, import_level: 2)
      # Use stop_headsign
      expect(
        feed_version.imported_schedule_stop_pairs.where(trip: 'AAMV1').pluck(:trip_headsign).uniq
      ).to match_array(["AAMV1 Test"])
      # Use trip_headsign
      expect(
        feed_version.imported_schedule_stop_pairs.where(trip: 'STBA').pluck(:trip_headsign).uniq
      ).to match_array(["Shuttle"])
      # Use last stop name
      expect(
        feed_version.imported_schedule_stop_pairs.where(trip: 'CITY1').pluck(:trip_headsign).uniq
      ).to match_array(["E Main St / S Irving St (Demo)"])
    end

    it 'can process a trip with 1 unique stop but at least 2 stop times' do
      # trip 'ONESTOP' has 1 unique stop, but 2 stop times
      feed, feed_version = load_feed(feed_version_name: :feed_version_example_trips_special_stop_times, import_level: 2)
      expect(feed.imported_route_stop_patterns.size).to eq(8)
      expect(RouteStopPattern.where(onestop_id: 'r-9qsb-20-67f86f-b61116').count).to eq (1)
      expect(RouteStopPattern.where(onestop_id: 'r-9qsb-20-67f86f-b61116').first.stop_distances).to eq ([0.0, 0.0])
    end
  end

  context 'to_trip_accessible' do
    def trips(values)
      values.map { |i| GTFS::Trip.new(wheelchair_accessible: i.to_s) }
    end

    it 'returns unknown if all 0' do
      expect(GTFSGraphImporter.new(nil,nil).send(:to_trips_accessible, trips([0,0]), :wheelchair_accessible)).to eq(:unknown)
    end

    it 'returns all_trips if all 1' do
      expect(GTFSGraphImporter.new(nil,nil).send(:to_trips_accessible, trips([1,1]), :wheelchair_accessible)).to eq(:all_trips)
    end

    it 'returns no_trips if all 2' do
      expect(GTFSGraphImporter.new(nil,nil).send(:to_trips_accessible, trips([2,2]), :wheelchair_accessible)).to eq(:no_trips)
    end

    it 'returns no_trips if all 2 or 0' do
      expect(GTFSGraphImporter.new(nil,nil).send(:to_trips_accessible, trips([2,0]), :wheelchair_accessible)).to eq(:no_trips)
    end

    it 'returns some_trips if mixed values but at least one 1' do
      expect(GTFSGraphImporter.new(nil,nil).send(:to_trips_accessible, trips([0,1]), :wheelchair_accessible)).to eq(:some_trips)
      expect(GTFSGraphImporter.new(nil,nil).send(:to_trips_accessible, trips([1,2]), :wheelchair_accessible)).to eq(:some_trips)
      expect(GTFSGraphImporter.new(nil,nil).send(:to_trips_accessible, trips([0,1,2]), :wheelchair_accessible)).to eq(:some_trips)
    end
  end

  context 'shape_dist_traveled' do

    context 'with nj path feed having shape_dist_traveled populated' do
      before(:all) {
        @feed, @feed_version = load_feed(feed_version_name: :feed_version_nj_path, import_level: 1)
      }
      after(:all) {
        DatabaseCleaner.clean_with :truncation, { except: ['spatial_ref_sys'] }
      }

      it 'utilizes shape_dist_traveled when available' do
        rsp = @feed.imported_route_stop_patterns.first
        # here we take advantage of the fact that there can be slight, allowable discrepancies between shape_dist_traveled and our algorithm.
        # It's possible the shape_dist_traveled given for the stop doesn't match the distance computed for the closest point
        # just want to make sure we're using the shape_dist_traveled ultimately
        expect(RouteStopPattern.find_by_onestop_id!(rsp.onestop_id).stop_distances).not_to match_array(Geometry::TLDistances.new(rsp).calculate_distances)
      end
    end

    context 'with nycdotsiferry and no shape_dist_traveled populated' do
      before(:all) {
        @feed, @feed_version = load_feed(feed_version_name: :feed_version_nycdotsiferry, import_level: 1)
      }
      after(:all) {
        DatabaseCleaner.clean_with :truncation, { except: ['spatial_ref_sys'] }
      }

      it 'recomputes distances of rsps with distance calculation issues' do
        # create a distance calc issue
        rsp = @feed.imported_route_stop_patterns.first
        rsp.update_column(:stop_distances, [100.0, 0.0])
        issue = Issue.create!(issue_type: 'distance_calculation_inaccurate', details: 'distance issue')
        issue.entities_with_issues.create!(entity: rsp, entity_attribute: 'geometry')
        issue.entities_with_issues.create!(entity: Stop.find_by_onestop_id!(rsp.stop_pattern[0]), entity_attribute: 'geometry')
        issue.entities_with_issues.create!(entity: Stop.find_by_onestop_id!(rsp.stop_pattern[1]), entity_attribute: 'geometry')
        # try the import again
        graph = GTFSGraphImporter.new(@feed, @feed_version)
        graph.create_change_osr
        expect(RouteStopPattern.find_by_onestop_id!(rsp.onestop_id).stop_distances).to match_array([0.0, 8138.0])
      end

      it 'recomputes distances when rsp stop distances are nil' do
        rsp = @feed.imported_route_stop_patterns.first
        rsp.update_column(:stop_distances, Array.new(rsp.stop_distances.size))
        graph = GTFSGraphImporter.new(@feed, @feed_version)
        graph.create_change_osr
        expect(RouteStopPattern.find_by_onestop_id!(rsp.onestop_id).stop_distances).to match_array([0.0, 8138.0])
      end
    end
  end
end
