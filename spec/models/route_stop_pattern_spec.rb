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
#  index_current_route_stop_patterns_on_stop_pattern  (stop_pattern) USING gin
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
      vexpect = [[-122.40181, 37.70667],[-122.40181, 37.70667]]
      rsp.geometry[:coordinates].zip(vexpect).each do |a,b|
        expect(a[0]).to be_within(0.001).of(b[0])
        expect(a[1]).to be_within(0.001).of(b[1])
      end
      # expect(rsp.geometry[:coordinates]).to eq
      expect(Geometry::TLDistances.new(rsp).calculate_distances).to eq [0.0,0.0]
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
    expect(Geometry::LineString.line_string([[1,2],[2,2]]).is_a?(RGeo::Geographic::SphericalLineStringImpl)).to be true
  end

  it '#set_precision' do
    expect(Geometry::Lib.set_precision([[-122.0123456,45.01234567],
                                           [-122.9123478,45.91234589]],RouteStopPattern::COORDINATE_PRECISION)).to match_array([[-122.01235,45.01235],[-122.91235,45.91235]])
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
    feed_version = create(:feed_version_example)
    rsp1 = create(:route_stop_pattern, stop_pattern: @sp, geometry: @geom, onestop_id: @onestop_id)
    rsp1.entities_imported_from_feed.create!(gtfs_id: 'trip1', feed: feed_version.feed, feed_version: feed_version)
    rsp1.entities_imported_from_feed.create!(gtfs_id: 'trip2', feed: feed_version.feed, feed_version: feed_version)
    rsp2 = create(:route_stop_pattern, stop_pattern: @sp, geometry: @geom, onestop_id: @onestop_id)
    rsp2.entities_imported_from_feed.create!(gtfs_id: 'trip3', feed: feed_version.feed, feed_version: feed_version)
    expect(RouteStopPattern.with_trips('trip1')).to match_array([rsp1])
    expect(RouteStopPattern.with_trips(['trip1','trip2'])).to match_array([rsp1])
    expect(RouteStopPattern.with_trips(['trip1','trip3'])).to match_array([rsp1, rsp2])
    expect(RouteStopPattern.with_trips('trip_missing')).to match_array([])
  end

  it 'ordered_ssp_trip_chunks' do
    feed_version = create(:feed_version_example)
    route = create(:route, onestop_id: @onestop_id)
    rsp = create(:route_stop_pattern, stop_pattern: @sp, geometry: @geom, onestop_id: @onestop_id)
    rsp.entities_imported_from_feed.create!(gtfs_id: 'trip1', feed: feed_version.feed, feed_version: feed_version)
    rsp.entities_imported_from_feed.create!(gtfs_id: 'trip2', feed: feed_version.feed, feed_version: feed_version)
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

  context 'without shape or shape points' do
    it 'generated RSP geometries from stop points when no shapes' do
      @feed, @feed_version = load_feed(feed_version_name: :feed_version_example_no_shapes, import_level: 1)
      rsp = @feed.imported_route_stop_patterns[0]
      expect(rsp.geometry[:coordinates]).to eq rsp.stop_pattern.map{ |onestop_id| Stop.find_by_onestop_id!(onestop_id).geometry[:coordinates].map{ |c| c.round(RouteStopPattern::COORDINATE_PRECISION)} }
    end
  end
end
