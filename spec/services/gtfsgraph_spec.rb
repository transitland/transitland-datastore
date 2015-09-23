require 'gtfsgraph'

def load_feed(import_level=1)
  path = 'spec/support/example_gtfs_archives/f-9q9-caltrain.zip'
  feed = create(:feed_caltrain)
  graph = GTFSGraph.new(File.join(Rails.root, path), feed)
  graph.load_gtfs
  operators = graph.load_tl
  graph.create_changeset(operators, import_level)
  feed
end

describe GTFSGraph do

  context 'can apply level 0 and 1 changesets' do

    before(:each) { @feed = load_feed(1) }

    it 'created a known Operator' do
      expect(@feed.operators.count).to eq(1)
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
      expect(@feed.routes.count).to eq(5)
      r = @feed.routes.find_by(onestop_id: 'r-9q9j-bullet')
      expect(r).to be_truthy
      expect(r.name).to eq('Bullet')
      expect(r.onestop_id).to eq('r-9q9j-bullet')
      # expect(r.identifiers).to match_array(["gtfs://f-9q9-caltrain/r/bullet"])
      expect(r.tags['vehicle_type']).to eq('rail')
      expect(r.tags['route_long_name']).to eq('Bullet')
      expect(r.geometry).to be
    end

    it 'created known Stops' do
      expect(@feed.stops.count).to eq(31)
      s = @feed.stops.find_by(onestop_id: 's-9q9k659e3r-sanjosecaltrainstation')
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
  end

  context 'can apply a level 2 changeset' do

    before(:each) { @feed = load_feed(2) }

    it 'created known ScheduleStopPairs' do
      expect(@feed.schedule_stop_pairs.count).to eq(4661) # EXACTLY.
      # Find a UNIQUE SSP, by origin, destination, route, trip.
      origin = @feed.stops.find_by!(
        onestop_id: 's-9q8yyugptw-sanfranciscocaltrainstation'
      )
      destination = @feed.stops.find_by!(
        onestop_id: 's-9q8yycs6ku-22ndstreetcaltrainstation'
      )
      route = @feed.routes.find_by!(
        onestop_id: 'r-9q9-local'
      )
      trip = '6507770-CT-14OCT-Caltrain-Saturday-02'
      found = @feed.schedule_stop_pairs.where(
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
      expect(s.trip).to eq(trip)
      expect(s.trip_headsign).to eq('San Jose Caltrain Station')
      expect(s.trip_short_name).to eq('422')
      expect(s.origin_timezone).to eq('America/Los_Angeles')
      expect(s.destination_timezone).to eq('America/Los_Angeles')
      expect(s.shape_dist_traveled).to eq(0.0)
      expect(s.timepoint).to be_nil
      expect(s.block_id).to be_nil
      expect(s.wheelchair_accessible).to eq(0)
      expect(s.pickup_type).to eq(0)
      expect(s.drop_off_type).to eq(0)
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
    end

  end

end
