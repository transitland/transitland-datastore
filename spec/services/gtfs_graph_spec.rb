describe GTFSGraph do

  context 'load operators' do
    it 'fails if no matching operator_in_feed' do
      feed_version = create(:feed_version_caltrain)
      feed = feed_version.feed
      oif = feed.operators_in_feed.first
      oif.update!({gtfs_agency_id:'not-found'})
      graph = GTFSGraph.new(feed, feed_version)
      expect { graph.create_change_osr }.to raise_error(GTFSGraph::Error)
    end
  end

  context 'to_trip_accessible' do
    def trips(values)
      values.map { |i| GTFS::Trip.new(wheelchair_accessible: i.to_s) }
    end

    it 'returns unknown if all 0' do
      expect(GTFSGraph.to_trips_accessible(trips([0,0]), :wheelchair_accessible)).to eq(:unknown)
    end

    it 'returns all_trips if all 1' do
      expect(GTFSGraph.to_trips_accessible(trips([1,1]), :wheelchair_accessible)).to eq(:all_trips)
    end

    it 'returns no_trips if all 2' do
      expect(GTFSGraph.to_trips_accessible(trips([2,2]), :wheelchair_accessible)).to eq(:no_trips)
    end

    it 'returns no_trips if all 2 or 0' do
      expect(GTFSGraph.to_trips_accessible(trips([2,0]), :wheelchair_accessible)).to eq(:no_trips)
    end

    it 'returns some_trips if mixed values but at least one 1' do
      expect(GTFSGraph.to_trips_accessible(trips([0,1]), :wheelchair_accessible)).to eq(:some_trips)
      expect(GTFSGraph.to_trips_accessible(trips([1,2]), :wheelchair_accessible)).to eq(:some_trips)
      expect(GTFSGraph.to_trips_accessible(trips([0,1,2]), :wheelchair_accessible)).to eq(:some_trips)
    end
  end

  context 'errors' do
    before(:each) {
      feed_version = create(:feed_version_example)
      feed = feed_version.feed
      @graph = GTFSGraph.new(feed, feed_version)
    }

    it 'fails and logs payload errors' do
      allow_any_instance_of(ChangePayload).to receive(:payload_validation_errors).and_return([{message: 'payload validation error'}])
      expect {
        @graph.create_change_osr
      }.to raise_error(Changeset::Error)
      expect(@graph.import_log.include?('payload validation error')).to be_truthy
    end
  end

  context 'can apply level 0 and 1 changesets' do

    context 'Caltrain' do
      before(:each) { @feed, @feed_version = load_feed(feed_version_name: :feed_version_caltrain, import_level: 1) }

      it 'updated feed geometry' do
        expect_coords = [[
          [-122.412076, 37.003485],
          [-121.566088, 37.003485],
          [-121.566088, 37.77639],
          [-122.412076, 37.77639],
          [-122.412076, 37.003485]
        ]]
        feed_coords = @feed.geometry(as: :geojson)[:coordinates]
        expect_coords.first.zip(feed_coords.first).each { |a,b|
          expect(a[0]).to be_within(0.001).of(b[0])
          expect(a[1]).to be_within(0.001).of(b[1])
        }
      end

      it 'created a known Operator' do
        expect(@feed.imported_operators.count).to eq(1)
        expect(@feed_version.imported_operators).to eq(@feed.imported_operators)
        o = @feed.operators.find_by(onestop_id: 'o-9q9-caltrain')
        expect(o).to be_truthy
        expect(o.name).to eq('Caltrain')
        expect(o.onestop_id).to eq('o-9q9-caltrain')
        expect(o.geometry).to be
        expect(o.identifiers).to contain_exactly("gtfs://f-9q9-caltrain/o/caltrain-ca-us")
        expect(o.timezone).to eq('America/Los_Angeles')
        expect(o.website).to eq('http://www.caltrain.com')
      end

      it 'created known Routes' do
        expect(@feed.imported_routes.count).to eq(5)
        expect(@feed_version.imported_routes).to eq(@feed.imported_routes)
        r = @feed.imported_routes.find_by(onestop_id: 'r-9q9j-bullet')
        expect(r).to be_truthy
        expect(r.name).to eq('Bullet')
        expect(r.onestop_id).to eq('r-9q9j-bullet')
        expect(r.identifiers).to match_array(["gtfs://f-9q9-caltrain/r/Bu-121"])
        expect(r.vehicle_type).to eq(:rail)
        expect(r.vehicle_type_value).to eq(2)
        expect(r.tags['route_long_name']).to eq('Bullet')
        expect(r.geometry).to be
        expect(r.wheelchair_accessible).to eq('unknown')
      end

      it 'created known Stops' do
        expect(@feed.imported_stops.count).to eq(95)
        expect(@feed_version.imported_stops).to eq(@feed.imported_stops)
        s = @feed.imported_stops.find_by(onestop_id: 's-9q9k659e3r-sanjosecaltrainstation')
        expect(s).to be_truthy
        expect(s.name).to eq('San Jose Caltrain Station')
        expect(s.onestop_id).to eq('s-9q9k659e3r-sanjosecaltrainstation')
        # expect(s.tags['']) # no tags
        expect(s.geometry).to be
        expect(s.identifiers).to contain_exactly(
          "gtfs://f-9q9-caltrain/s/ctsj"
        )
        expect(s.timezone).to eq('America/Los_Angeles')
      end

      it 'created known RouteStopPatterns' do
        expect(@feed.imported_route_stop_patterns.count).to eq(51)
      end

      it 'created known Route that traverses known Route Stop Patterns' do
        r = @feed.imported_routes.find_by(onestop_id: 'r-9q9j-bullet')
        expect(r.route_stop_patterns.size).to eq(12)
        expect(r.route_stop_patterns.map(&:onestop_id)).to contain_exactly(
            "r-9q9j-bullet-ed69fc-5f96a1",
            "r-9q9j-bullet-1de4fb-725db6",
            "r-9q9j-bullet-cfa925-5f96a1",
            "r-9q9j-bullet-2e5135-725db6",
            "r-9q9j-bullet-4fea71-725db6",
            "r-9q9j-bullet-804eb5-5f96a1",
            "r-9q9j-bullet-b18930-5f96a1",
            "r-9q9j-bullet-bed20a-5f96a1",
            "r-9q9j-bullet-8f1c16-6724bf",
            "r-9q9j-bullet-3fbb97-725db6",
            "r-9q9j-bullet-d2a2b0-725db6",
            "r-9q9j-bullet-899813-f23867"
        )
      end

      it 'calculated and stored distances for Route Stop Patterns' do
        expect(@feed.imported_route_stop_patterns[0].stop_distances).to match_array([46.1, 2565.9, 8002.4, 14688.5,
          17656.6, 21810.1, 24362.9, 26122.0, 28428.0, 30576.9, 32583.5, 35274.7, 37262.8, 40756.8, 44607.6, 46357.8,
          48369.9, 50918.5, 54858.4, 57964.7, 62275.7, 65457.2, 71336.4, 75359.4].map{|value| be_within(2.0).of(value)})
      end

      it 'created known Operator that serves known Routes' do
        o = @feed.imported_operators.find_by(onestop_id: 'o-9q9-caltrain')
        expect(o.routes.size).to eq(5)
        expect(o.routes.map(&:onestop_id)).to contain_exactly(
          "r-9q9j-bullet",
          "r-9q9-limited",
          "r-9q9-local",
          "r-9q9k6-tamien~sanjosediridoncaltrainshuttle",
          "r-9q8yw-sx"
        )
      end

      it 'created known Operator that serves known Stops' do
        o = @feed.imported_operators.find_by(onestop_id: 'o-9q9-caltrain')
        # Just check the number of stops here...
        expect(o.stops.size).to eq(64)
      end

      it 'created known Routes that serve known Stops' do
        r = @feed.imported_routes.find_by(onestop_id: 'r-9q9j-bullet')
        expect(r.stops.size).to eq(26)
        expect(r.stops.map(&:onestop_id)).to match_array([
          "s-9q8vzhbggj-millbraecaltrainstation<70061",
          "s-9q8vzhbggj-millbraecaltrainstation<70062",
          "s-9q8yw8y448-bayshorecaltrainstation<70031",
          "s-9q8yw8y448-bayshorecaltrainstation<70032",
          "s-9q8yycs6ku-22ndstreetcaltrainstation<70021",
          "s-9q8yycs6ku-22ndstreetcaltrainstation<70022",
          "s-9q8yyugptw-sanfranciscocaltrainstation<70011",
          "s-9q8yyugptw-sanfranciscocaltrainstation<70012",
          "s-9q9hwp6epk-mountainviewcaltrainstation<70211",
          "s-9q9hwp6epk-mountainviewcaltrainstation<70212",
          "s-9q9hxhecje-sunnyvalecaltrainstation<70221",
          "s-9q9hxhecje-sunnyvalecaltrainstation<70222",
          "s-9q9j5dmkuu-menloparkcaltrainstation<70161",
          "s-9q9j5dmkuu-menloparkcaltrainstation<70162",
          "s-9q9j6812kg-redwoodcitycaltrainstation<70141",
          "s-9q9j6812kg-redwoodcitycaltrainstation<70142",
          "s-9q9j8rn6tv-sanmateocaltrainstation<70091",
          "s-9q9j8rn6tv-sanmateocaltrainstation<70092",
          "s-9q9j913rf1-hillsdalecaltrainstation<70111",
          "s-9q9j913rf1-hillsdalecaltrainstation<70112",
          "s-9q9jh061xw-paloaltocaltrainstation<70171",
          "s-9q9jh061xw-paloaltocaltrainstation<70172",
          "s-9q9k62qu53-tamiencaltrainstation<70271",
          "s-9q9k62qu53-tamiencaltrainstation<70272",
          "s-9q9k659e3r-sanjosecaltrainstation<70261",
          "s-9q9k659e3r-sanjosecaltrainstation<70262"
        ])
      end
    end

    it 'skipped RouteStopPattern generation with trips having less than 2 stop times' do
      @feed, @feed_version = load_feed(feed_version_name: :feed_version_example_trips_special_stop_times, import_level: 1)
      # 'BFC2' is a 1 stop time trip; 'BFC1' has no stop times
      expect(@feed.imported_route_stop_patterns.size).to eq 8
    end
  end


  context 'can apply a level 2 changeset', import_level:2 do

    it 'ignores missing routes' do
      # Delete a route & rsp before SSPs are processed ->
      #     expect SSPs for this route & rsp trips to be skipped
      block_before_level_2 = Proc.new { |graph|
        Route.find_by_onestop_id!('r-9qsb-20').delete
        RouteStopPattern.find_by_onestop_id!('r-9qt1-50-5cba7c-25211f').delete
      }
      @feed, @feed_version = load_feed(feed_version_name: :feed_version_example, import_level: 2, block_before_level_2: block_before_level_2)
      expect(@feed.imported_schedule_stop_pairs.count).to eq(45) # WAS 17
      expect(@feed.imported_schedule_stop_pairs.where(route: Route.find_by_onestop_id('r-9qt1-50')).count).to eq(2) # WAS 4
    end

    it 'created known ScheduleStopPairs' do
      @feed, @feed_version = load_feed(feed_version_name: :feed_version_example, import_level: 2)
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
      expect(s.destination_dist_traveled).to eq 875.4
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
      expect(s.frequency_start_time).to eq('6:00:00')
      expect(s.frequency_end_time).to eq('7:59:59')
      expect(s.frequency_headway_seconds).to eq(1800)
      expect(s.frequency_type).to eq('window')
    end

    it 'can process a trip with 1 unique stop but at least 2 stop times' do
      # trip 'ONESTOP' has 1 unique stop, but 2 stop times
      @feed, @feed_version = load_feed(feed_version_name: :feed_version_example_trips_special_stop_times, import_level: 2)
      expect(@feed.imported_route_stop_patterns.size).to eq(8)
      expect(RouteStopPattern.where(onestop_id: 'r-9qsb-20-67f86f-b61116').count).to eq (1)
      expect(RouteStopPattern.where(onestop_id: 'r-9qsb-20-67f86f-b61116').first.stop_distances).to eq ([0.0, 0.0])
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
      @feed, @feed_version = load_feed(feed_version_name: :feed_version_example_trips_special_stop_times, import_level: 2)
      # Use stop_headsign
      expect(
        @feed_version.imported_schedule_stop_pairs.where(trip: 'AAMV1').pluck(:trip_headsign).uniq
      ).to match_array(["AAMV1 Test"])
      # Use trip_headsign
      expect(
        @feed_version.imported_schedule_stop_pairs.where(trip: 'STBA').pluck(:trip_headsign).uniq
      ).to match_array(["Shuttle"])
      # Use last stop name
      expect(
        @feed_version.imported_schedule_stop_pairs.where(trip: 'CITY1').pluck(:trip_headsign).uniq
      ).to match_array(["E Main St / S Irving St (Demo)"])
    end
  end

  context 'new feed version integration' do

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
      expect(@feed.imported_routes.size).to eq 11
      expect(@feed.imported_stops.size).to eq 19
      expect(@feed.imported_routes.uniq.size).to eq 6
      expect(@feed.imported_routes.find_by_onestop_id('r-9qscy-60')).to be_truthy
      expect(@feed.imported_stops.find_by_onestop_id('s-9qt1hbwder-newstop')).to be_truthy
    end

    it 'does not delete a previous feed version entity' do
      expect(@feed.imported_routes.size).to eq 5
      expect(@feed.imported_stops.size).to eq 9
      expect(@feed.imported_routes.find_by_onestop_id('r-9qscy-10')).to be_truthy
      load_feed(feed_version: @feed_version_update_delete, import_level: 1)
      expect(@original_feed_version.imported_routes.find_by_onestop_id('r-9qscy-10')).to be_truthy
      expect(@feed_version_update_delete.imported_routes.find_by_onestop_id('r-9qscy-10')).to be_falsey
      expect(@feed_version_update_delete.imported_stops.find_by_onestop_id('s-9qsczn2rk0-emainst~sirvingstdemo')).to be_falsey
      expect(@feed.imported_routes.size).to eq 10
      expect(@feed.imported_stops.size).to eq 17
    end

    it 'updates previous matching feed version entities with new attribute values' do
      expect(@feed.imported_routes.find_by_onestop_id('r-9qscy-10').vehicle_type).to eq 'bus'
      load_feed(feed_version: @feed_version_update_add, import_level: 1)
      expect(@feed.imported_routes.find_by_onestop_id('r-9qscy-10').vehicle_type).to eq 'rail'
    end

    it 'does not modify previous matching feed version entitie\'s unchangeable attributes' do
      original_creation_time = @feed.imported_stops.find_by_onestop_id('s-9qscv9zzb5-bullfrogdemo').created_at
      load_feed(feed_version: @feed_version_update_add, import_level: 1)
      expect(@feed_version_update_add.imported_stops.find_by_onestop_id('s-9qscv9zzb5-bullfrogdemo').created_at).to eq original_creation_time
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
end
