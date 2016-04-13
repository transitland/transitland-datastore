describe GTFSGraph do

  context 'load operators' do
    it 'fails if no matching operator_in_feed' do
      feed_version = create(:feed_version_caltrain)
      feed = feed_version.feed
      oif = feed.operators_in_feed.first
      oif.update!({gtfs_agency_id:'not-found'})
      graph = GTFSGraph.new(feed_version.file.path, feed, feed_version)
      expect { graph.create_change_osr }.to raise_error(GTFSGraph::Error)
    end
  end

  context 'can apply level 0 and 1 changesets' do
    before(:each) { @feed, @feed_version = load_feed(feed_version_name: :feed_version_caltrain, import_level: 1) }

    it 'updated feed geometry' do
      geometry = [
        [
          [-122.412076, 37.003485],
          [-121.566088, 37.003485],
          [-121.566088, 37.776439],
          [-122.412076, 37.776439],
          [-122.412076, 37.003485]
        ]
      ]
      expect(@feed.geometry(as: :geojson)[:coordinates]).to match_array(geometry)
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
        "r-9q9j-bullet-06b68d-0bca5d",
        "r-9q9j-bullet-078a92-c05b8d",
        "r-9q9j-bullet-49de87-0bca5d",
        "r-9q9j-bullet-6168c2-0bca5d",
        "r-9q9j-bullet-752be5-0bca5d",
        "r-9q9j-bullet-761397-6e2d1a",
        "r-9q9j-bullet-9a247a-6e2d1a",
        "r-9q9j-bullet-c43c1d-0bca5d",
        "r-9q9j-bullet-cf14f2-6e2d1a",
        "r-9q9j-bullet-d1201b-6e2d1a",
        "r-9q9j-bullet-dea476-6e2d1a",
        "r-9q9j-bullet-e11172-ba265d"
      )
    end

    it 'calculated and stored distances for Route Stop Patterns' do
      puts @feed.imported_route_stop_patterns[0].onestop_id
      expect(@feed.imported_route_stop_patterns[0].stop_distances).to match_array([46.1, 2565.9, 8002.4, 14688.5, 17656.6, 21810.1, 24362.9, 26122.0, 28428.0, 30576.9, 32583.5, 35274.7, 37262.8, 40756.8, 44607.6, 46357.8, 48369.9, 50918.5, 54858.4, 57964.7, 62275.7, 65457.2, 71336.4, 75359.4])
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
      expect(o.stops.size).to eq(95)
    end

    it 'created known Routes that serve known Stops' do
      r = @feed.imported_routes.find_by(onestop_id: 'r-9q9j-bullet')
      expect(r.stops.size).to eq(39)
      expect(r.stops.map(&:onestop_id)).to contain_exactly(
        "s-9q8vzhbggj-millbraecaltrainstation",
        "s-9q8vzhbggj-millbraecaltrainstation<70061",
        "s-9q8vzhbggj-millbraecaltrainstation<70062",
        "s-9q8yw8y448-bayshorecaltrainstation",
        "s-9q8yw8y448-bayshorecaltrainstation<70031",
        "s-9q8yw8y448-bayshorecaltrainstation<70032",
        "s-9q8yycs6ku-22ndstreetcaltrainstation",
        "s-9q8yycs6ku-22ndstreetcaltrainstation<70021",
        "s-9q8yycs6ku-22ndstreetcaltrainstation<70022",
        "s-9q8yyugptw-sanfranciscocaltrainstation",
        "s-9q8yyugptw-sanfranciscocaltrainstation<70011",
        "s-9q8yyugptw-sanfranciscocaltrainstation<70012",
        "s-9q9hwp6epk-mountainviewcaltrainstation",
        "s-9q9hwp6epk-mountainviewcaltrainstation<70211",
        "s-9q9hwp6epk-mountainviewcaltrainstation<70212",
        "s-9q9hxhecje-sunnyvalecaltrainstation",
        "s-9q9hxhecje-sunnyvalecaltrainstation<70221",
        "s-9q9hxhecje-sunnyvalecaltrainstation<70222",
        "s-9q9j5dmkuu-menloparkcaltrainstation",
        "s-9q9j5dmkuu-menloparkcaltrainstation<70161",
        "s-9q9j5dmkuu-menloparkcaltrainstation<70162",
        "s-9q9j6812kg-redwoodcitycaltrainstation",
        "s-9q9j6812kg-redwoodcitycaltrainstation<70141",
        "s-9q9j6812kg-redwoodcitycaltrainstation<70142",
        "s-9q9j8rn6tv-sanmateocaltrainstation",
        "s-9q9j8rn6tv-sanmateocaltrainstation<70091",
        "s-9q9j8rn6tv-sanmateocaltrainstation<70092",
        "s-9q9j913rf1-hillsdalecaltrainstation",
        "s-9q9j913rf1-hillsdalecaltrainstation<70111",
        "s-9q9j913rf1-hillsdalecaltrainstation<70112",
        "s-9q9jh061xw-paloaltocaltrainstation",
        "s-9q9jh061xw-paloaltocaltrainstation<70171",
        "s-9q9jh061xw-paloaltocaltrainstation<70172",
        "s-9q9k62qu53-tamiencaltrainstation",
        "s-9q9k62qu53-tamiencaltrainstation<70271",
        "s-9q9k62qu53-tamiencaltrainstation<70272",
        "s-9q9k659e3r-sanjosecaltrainstation",
        "s-9q9k659e3r-sanjosecaltrainstation<70261",
        "s-9q9k659e3r-sanjosecaltrainstation<70262"
      )
    end
  end

  context 'can apply a level 2 changeset', import_level:2 do

    it 'created known ScheduleStopPairs' do
      @feed, @feed_version = load_feed(feed_version_name: :feed_version_caltrain, import_level: 2)
      expect(@feed.imported_schedule_stop_pairs.count).to eq(4661) # EXACTLY.
      expect(@feed_version.imported_schedule_stop_pairs.pluck(:id)).to match_array(@feed.imported_schedule_stop_pairs.pluck(:id))
      # Find a UNIQUE SSP, by origin, destination, route, trip.
      origin = @feed.imported_stops.find_by!(
        onestop_id: "s-9q8yyugptw-sanfranciscocaltrainstation<70012"
      )
      destination = @feed.imported_stops.find_by!(
        onestop_id: "s-9q8yycs6ku-22ndstreetcaltrainstation<70022"
      )
      route = @feed.imported_routes.find_by!(onestop_id: 'r-9q9-local')
      route_stop_pattern = @feed.imported_route_stop_patterns.find_by!(onestop_id: 'r-9q9-local-260874-6e2d1a')
      operator = @feed.operators.find_by(onestop_id: 'o-9q9-caltrain')
      trip = '6507770-CT-14OCT-Caltrain-Saturday-02'
      found = @feed.imported_schedule_stop_pairs.where(
        origin: origin,
        destination: destination,
        route: route,
        trip: trip
      )
      expect(found.count).to eq(1)
      s = found.first
      expect(s).to be_truthy
      expect(s.origin).to eq(origin)
      expect(s.destination).to eq(destination)
      expect(s.route).to eq(route)
      expect(s.route_stop_pattern).to eq(route_stop_pattern)
      expect(s.operator).to eq(operator)
      expect(s.trip).to eq(trip)
      expect(s.trip_headsign).to eq('San Jose Caltrain Station')
      expect(s.trip_short_name).to eq('422')
      expect(s.origin_timezone).to eq('America/Los_Angeles')
      expect(s.destination_timezone).to eq('America/Los_Angeles')
      expect(s.shape_dist_traveled).to eq(0.0)
      expect(s.block_id).to be_nil
      expect(s.wheelchair_accessible).to eq(nil)
      expect(s.bikes_allowed).to eq(nil)
      expect(s.pickup_type).to eq(nil)
      expect(s.drop_off_type).to eq(nil)
      expect(s.origin_arrival_time).to eq('08:15:00')
      expect(s.origin_departure_time).to eq('08:15:00')
      expect(s.destination_arrival_time).to eq('08:20:00')
      expect(s.destination_departure_time).to eq('08:20:00')
      expect(s.origin_dist_traveled).to eq 46.1
      expect(s.destination_dist_traveled).to eq 2565.9
      expect(s.service_days_of_week).to match_array(
        [false, false, false, false, false, true, false]
      )
      expect(s.service_added_dates.map(&:to_s)).to contain_exactly('2015-11-27')
      expect(s.service_except_dates.map(&:to_s)).to contain_exactly('2015-06-06', '2015-07-04')
      expect(s.service_start_date.to_s).to eq('2015-05-02')
      expect(s.service_end_date.to_s).to eq('2024-10-05')
      expect(s.origin_timepoint_source).to eq('gtfs_exact')
      expect(s.destination_timepoint_source).to eq('gtfs_exact')
      expect(s.window_start).to eq('08:15:00')
      expect(s.window_end).to eq('08:20:00')
    end

    it 'correctly assigned distances to schedule stop pairs containing stops repeated in its Route Stop Pattern' do
      @feed, @feed_version = load_feed(feed_version_name: :feed_version_vta_1930705, import_level: 2)
      origin = @feed.imported_stops.find_by!(
        onestop_id: "s-9q9kf4gkqz-greatmall~maintransitcenter"
      )
      destination = @feed.imported_stops.find_by!(
        onestop_id: "s-9q9kf51txf-main~greatmallparkway"
      )
      route = @feed.imported_routes.find_by!(onestop_id: 'r-9q9k-66')
      trip = '1930705'
      first_found = @feed.imported_schedule_stop_pairs.where(
        destination: origin,
        route: route,
        trip: trip
      )
      second_found = @feed.imported_schedule_stop_pairs.where(
        origin: origin,
        destination: destination,
        route: route,
        trip: trip
      )
      ssp1 = first_found.first
      ssp2 = second_found.first
      expect(ssp2.destination_dist_traveled).to be > ssp1.origin_dist_traveled
    end
  end

  context 'new feed version integration' do

    before(:each) {
      @feed, @original_feed_version = load_feed(feed_version_name: :feed_version_example, import_level: 2)
      @feed_version_update_add = create(:feed_version_example_update_add, feed: @feed)
      @feed_version_update_delete = create(:feed_version_example_update_delete, feed: @feed)
    }

    it 'creates a new tl entity not found in previous feed version' do
      expect(@feed.imported_stops.size).to eq 9
      expect(@feed.imported_routes.size).to eq 5
      expect(@feed.imported_routes.find_by_onestop_id('r-9qscy-60')).to be_falsey
      load_feed(feed_version: @feed_version_update_add, import_level: 2)
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
      load_feed(feed_version: @feed_version_update_delete, import_level: 2)
      expect(@original_feed_version.imported_routes.find_by_onestop_id('r-9qscy-10')).to be_truthy
      expect(@feed_version_update_delete.imported_routes.find_by_onestop_id('r-9qscy-10')).to be_falsey
      expect(@feed_version_update_delete.imported_stops.find_by_onestop_id('s-9qsczn2rk0-emainst~sirvingstdemo')).to be_falsey
      expect(@feed.imported_routes.size).to eq 10
      expect(@feed.imported_stops.size).to eq 17
    end

    it 'updates previous matching feed version entities with new attribute values' do
      expect(@feed.imported_routes.find_by_onestop_id('r-9qscy-10').vehicle_type).to eq 'bus'
      load_feed(feed_version: @feed_version_update_add, import_level: 2)
      expect(@feed.imported_routes.find_by_onestop_id('r-9qscy-10').vehicle_type).to eq 'rail'
    end

    it 'does not modify previous matching feed version entitie\'s unchangeable attributes' do
      original_creation_time = @feed.imported_stops.find_by_onestop_id('s-9qscv9zzb5-bullfrogdemo').created_at
      load_feed(feed_version: @feed_version_update_add, import_level: 2)
      expect(@feed_version_update_add.imported_stops.find_by_onestop_id('s-9qscv9zzb5-bullfrogdemo').created_at).to eq original_creation_time
    end
  end
end
