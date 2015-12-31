def load_feed(import_level=1)
  feed_version = create(:feed_version_caltrain)
  feed = feed_version.feed
  graph = GTFSGraph.new(feed_version.file.path, feed, feed_version)
  graph.create_change_osr(import_level)
  if import_level >= 2
    graph.ssp_schedule_async do |trip_ids, agency_map, route_map, stop_map|
      graph.ssp_perform_async(trip_ids, agency_map, route_map, stop_map)
    end
  end
  return feed, feed_version
end

describe GTFSGraph do

  context 'can apply level 0 and 1 changesets' do
    before(:each) { @feed, @feed_version = load_feed(1) }

    it 'updated feed geometry' do
      geometry = [
        [
          [-122.412018, 37.003606],
          [-121.566497, 37.003606],
          [-121.566497, 37.776439],
          [-122.412018, 37.776439],
          [-122.412018, 37.003606]
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

    it 'created known Stops', :test_stops => true do
      expect(@feed.imported_stops.count).to eq(31)
      expect(@feed_version.imported_stops).to eq(@feed.imported_stops)
      s = @feed.imported_stops.find_by(onestop_id: 's-9q9k659e3r-sanjosecaltrainstation')
      expect(s).to be_truthy
      expect(s.name).to eq('San Jose Caltrain Station')
      expect(s.onestop_id).to eq('s-9q9k659e3r-sanjosecaltrainstation')
      # expect(s.tags['']) # no tags
      expect(s.geometry).to be
      expect(s.identifiers).to contain_exactly(
        "gtfs://f-9q9-caltrain/s/ctsj",
        "gtfs://f-9q9-caltrain/s/70261",
        "gtfs://f-9q9-caltrain/s/70262",
        "gtfs://f-9q9-caltrain/s/777402"
      )
      expect(s.timezone).to eq('America/Los_Angeles')
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
      expect(o.stops.size).to eq(31)
    end

    it 'created known Routes that serve known Stops' do
      r = @feed.imported_routes.find_by(onestop_id: 'r-9q9j-bullet')
      expect(r.stops.size).to eq(13)
      expect(r.stops.map(&:onestop_id)).to contain_exactly(
        "s-9q8vzhbggj-millbraecaltrainstation",
        "s-9q8yw8y448-bayshorecaltrainstation",
        "s-9q8yycs6ku-22ndstreetcaltrainstation",
        "s-9q8yyugptw-sanfranciscocaltrainstation",
        "s-9q9hwp6epk-mountainviewcaltrainstation",
        "s-9q9hxhecje-sunnyvalecaltrainstation",
        "s-9q9j5dmkuu-menloparkcaltrainstation",
        "s-9q9j6812kg-redwoodcitycaltrainstation",
        "s-9q9j8rn6tv-sanmateocaltrainstation",
        "s-9q9j913rf1-hillsdalecaltrainstation",
        "s-9q9jh061xw-paloaltocaltrainstation",
        "s-9q9k62qu53-tamiencaltrainstation",
        "s-9q9k659e3r-sanjosecaltrainstation"
      )
    end
  end

  context 'can apply a level 2 changeset' do

    before(:each) { @feed, @feed_version = load_feed(2) }

    it 'created known ScheduleStopPairs' do
      expect(@feed.imported_schedule_stop_pairs.count).to eq(4661) # EXACTLY.
      expect(@feed_version.imported_schedule_stop_pairs.pluck(:id)).to match_array(@feed.imported_schedule_stop_pairs.pluck(:id))
      # Find a UNIQUE SSP, by origin, destination, route, trip.
      origin = @feed.imported_stops.find_by!(
        onestop_id: 's-9q8yyugptw-sanfranciscocaltrainstation'
      )
      destination = @feed.imported_stops.find_by!(
        onestop_id: 's-9q8yycs6ku-22ndstreetcaltrainstation'
      )
      route = @feed.imported_routes.find_by!(onestop_id: 'r-9q9-local')
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
  end
end
