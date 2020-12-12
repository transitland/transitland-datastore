# == Schema Information
#
# Table name: current_stops
#
#  id                                 :integer          not null, primary key
#  onestop_id                         :string
#  geometry                           :geography({:srid geometry, 4326
#  tags                               :hstore
#  created_at                         :datetime
#  updated_at                         :datetime
#  name                               :string
#  created_or_updated_in_changeset_id :integer
#  version                            :integer
#  timezone                           :string
#  last_conflated_at                  :datetime
#  type                               :string
#  parent_stop_id                     :integer
#  osm_way_id                         :integer
#  edited_attributes                  :string           default([]), is an Array
#  wheelchair_boarding                :boolean
#  directionality                     :integer
#  geometry_reversegeo                :geography({:srid point, 4326
#
# Indexes
#
#  #c_stops_cu_in_changeset_id_index           (created_or_updated_in_changeset_id)
#  index_current_stops_on_geometry             (geometry) USING gist
#  index_current_stops_on_geometry_reversegeo  (geometry_reversegeo) USING gist
#  index_current_stops_on_onestop_id           (onestop_id) UNIQUE
#  index_current_stops_on_parent_stop_id       (parent_stop_id)
#  index_current_stops_on_tags                 (tags)
#  index_current_stops_on_updated_at           (updated_at)
#  index_current_stops_on_wheelchair_boarding  (wheelchair_boarding)
#

describe Stop do
  let (:geometry_point) { { type: 'Point', coordinates: [-122.433416, 37.732525] } }
  let (:geometry_point2) { { type: 'Point', coordinates: [-123.0, 38.0] } }
  let (:geometry_polygon) {
    {
      type: 'Polygon',
      coordinates: [[
        [-122.421947,37.772829],[-122.418206,37.752327],[-122.299818,37.535186],[-122.148715,37.393842],[-122.145893,37.393447],[-121.900157,37.413861],[-121.894138,37.4317],[-121.945377,38.017443],[-122.349579,37.996726],[-122.354525,37.993171],[-122.386786,37.92887],[-122.421947,37.772829]
      ]]
    }
  }

  it 'can be created' do
    stop = create(:stop)
    expect(Stop.exists?(stop.id)).to be true
  end

  it "won't have extra spaces in its name" do
    stop = create(:stop, name: ' Main St. Stop ')
    expect(stop.name).to eq 'Main St. Stop'
  end

  context 'directionality' do
    it 'allows 1/enter' do
      stop = create(:stop)
      stop.update!(directionality: 'enter')
      expect(stop.reload.directionality).to eq(:enter)
      stop.update!(directionality: 1)
      expect(stop.reload.directionality).to eq(:enter)
    end
    it 'allows 2/exit' do
      stop = create(:stop)
      stop.update!(directionality: 'exit')
      expect(stop.reload.directionality).to eq(:exit)
      stop.update!(directionality: 2)
      expect(stop.reload.directionality).to eq(:exit)
    end
    it 'allows 0/both' do
      stop = create(:stop)
      stop.update!(directionality: 'both')
      expect(stop.reload.directionality).to eq(:both)
      stop.update!(directionality: 0)
      expect(stop.reload.directionality).to eq(:both)
      # stop.update!(directionality: nil)
      # expect(stop.reload.directionality).to eq(:both)
    end
  end

  context 'geometry' do
    it 'can be specified with WKT' do
      stop = create(:stop, geometry: 'POINT(-122.433416 37.732525)')
      expect(Stop.exists?(stop.id)).to be true
      expect(stop.geometry).to eq({ type: 'Point', coordinates: [-122.433416, 37.732525] })
    end

    it 'can be specified with GeoJSON' do
      geojson = { type: 'Point', coordinates: [-122.433416, 37.732525] }
      stop = create(:stop, geometry: geojson)
      expect(Stop.exists?(stop.id)).to be true
      expect(stop.geometry).to eq geojson
    end

    it 'can be read as GeoJSON (by default)' do
      geojson = { type: 'Point', coordinates: [-122.433416, 37.732525] }
      stop = create(:stop, geometry: geojson)
      expect(stop.geometry).to eq geojson
    end

    it 'can be read as WKT' do
      stop = create(:stop, geometry: { type: 'Point', coordinates: [-122.433416, 37.732525] })
      expect(stop.geometry(as: :wkt).to_s).to eq('POINT (-122.433416 37.732525)')
    end

    it 'can be specified via changeset' do
      stop = create(:stop)
      c = {changes: [{action: :createUpdate, stop: {onestopId: stop.onestop_id, geometry: geometry_point}}]}
      Changeset.new(payload: c).apply!
      stop.reload
      expect(stop.geometry).to eq geometry_point
    end

    it 'can accept a polygon via changeset' do
      stop = create(:stop)
      c = {changes: [{action: :createUpdate, stop: {onestopId: stop.onestop_id, geometry: geometry_polygon}}]}
      Changeset.new(payload: c).apply!
      stop.reload
      expect(stop.geometry).to eq geometry_polygon
    end

    it 'works with rsp distance recalculation changeset' do
      stop1 = create(:stop, geometry: {"type": "Point", "coordinates": [-122.39999,37.79042]})
      stop2 = create(:stop, geometry: {"type": "Point", "coordinates": [-122.39614,37.79349]})
      station_polygon = { "type": "Polygon", "coordinates": [ [ [ -122.39650368690491, 37.79352034138864 ], [ -122.39815592765808, 37.79227403735882 ], [ -122.39809691905974, 37.79196457765796 ], [ -122.39771068096161, 37.791943381740616 ], [ -122.3960906267166, 37.79321512601903 ], [ -122.39621400833128, 37.79349066772748 ], [ -122.39650368690491, 37.79352034138864 ] ] ] }
      rsp = create(:route_stop_pattern, stop_distances: [0, 481.1], stop_pattern: [stop1.onestop_id, stop2.onestop_id], geometry: {"type": "LineString","coordinates": [[-122.39999,37.79042],[-122.39614,37.79349]]})
      c = {changes: [{action: :createUpdate, stop: {onestopId: stop2.onestop_id, geometry: station_polygon}}]}
      Changeset.create!(payload: c).apply!
      stop2.reload
      rsp.reload
      expect(stop2.geometry).to eq station_polygon
      expect(rsp.stop_distances.last).to be_within(0.01).of(357.6)
    end
  end

  context 'geometry_reversegeo' do
    it 'can be specified with WKT' do
        stop = create(:stop, geometry_reversegeo: 'POINT(-122.433416 37.732525)')
        expect(Stop.exists?(stop.id)).to be true
        expect(stop.geometry_reversegeo).to eq({ type: 'Point', coordinates: [-122.433416, 37.732525] })
    end

    it 'can be specified with GeoJSON' do
      stop = create(:stop, geometry_reversegeo: geometry_point)
      expect(Stop.exists?(stop.id)).to be true
      expect(stop.geometry_reversegeo).to eq geometry_point
    end

    it 'can be read as GeoJSON (by default)' do
      stop = create(:stop, geometry_reversegeo: geometry_point)
      expect(stop.geometry_reversegeo).to eq geometry_point
    end

    it 'can be read as WKT' do
      stop = create(:stop, geometry_reversegeo: geometry_point)
      expect(stop.geometry_reversegeo(as: :wkt).to_s).to eq('POINT (-122.433416 37.732525)')
    end

    it 'can be specified via changeset' do
      stop = create(:stop)
      c = {changes: [{action: :createUpdate, stop: {onestopId: stop.onestop_id, geometryReversegeo: geometry_point}}]}
      Changeset.new(payload: c).apply!
      stop.reload
      expect(stop.geometry_reversegeo).to eq geometry_point
    end

    it 'rejects polygons' do
      expect {
        create(:stop, geometry_reversegeo: geometry_polygon)
      }.to raise_error(ActiveRecord::StatementInvalid)
    end

    it 'rejects polygons in changeset' do
      stop = create(:stop)
      c = {changes: [{action: :createUpdate, stop: {onestopId: stop.onestop_id, geometryReversegeo: geometry_polygon}}]}
      expect {
        Changeset.new(payload: c).apply!
      }.to raise_error(Changeset::Error)
    end
  end

  context 'convex_hull' do
    it 'can compute a convex hull around multiple stops' do
      # using similar points to http://turfjs.org/static/docs/module-turf_convex.html
      s1 = build(:stop, geometry: { type: 'Point', coordinates: [10.195312, 43.755225] })
      s2 = build(:stop, geometry: { type: 'Point', coordinates: [10.404052, 43.8424511] })
      s3 = build(:stop, geometry: { type: 'Point', coordinates: [10.579833, 43.659924] })
      s4 = build(:stop, geometry: { type: 'Point', coordinates: [10.360107, 43.516688] })
      s5 = build(:stop, geometry: { type: 'Point', coordinates: [10.14038, 43.588348] })
      s6 = build(:stop, geometry: { type: 'Point', coordinates: [10.255312, 43.605225] })
      s7 = build(:stop, geometry: { type: 'Point', coordinates: [10.394439, 43.902839] })

      unprojected_convex_hull = Stop.convex_hull([s1,s2,s3,s4,s5,s6,s7], as: :wkt)
      expect(unprojected_convex_hull.exterior_ring.num_points).to eq 6

      projected_convex_hull = Stop.convex_hull([s1,s2,s3,s4,s5,s6,s7], as: :wkt, projected: true)
      [s1,s2,s3,s4,s5,s6,s7].each do |stop|
        touches = stop.geometry(as: :wkt, projected: true).touches?(projected_convex_hull)
        within = stop.geometry(as: :wkt, projected: true).within?(projected_convex_hull)
        expect(touches || within).to eq true
      end
    end

    it 'works if with polygon geometries' do
      # verified via geojson.io
      s1 = build(:stop, geometry: geometry_point)
      s2 = build(:stop, geometry: geometry_point2)
      s3 = build(:stop, geometry: geometry_polygon)
      unprojected_convex_hull = Stop.convex_hull([s1,s2,s3], as: :wkt)
      expect(unprojected_convex_hull.exterior_ring.num_points).to eq 7
      expected_coordinates = [[
        [-122.145893, 37.393446999999995],
        [-122.14871499999997, 37.39384199999998],
        [-123.00000000000001, 38.0],
        [-121.945377, 38.017442999999986],
        [-121.894138, 37.43169999999998],
        [-121.90015699999998, 37.413860999999976],
        [-122.145893, 37.393446999999995]
      ]]
      unprojected_convex_hull.coordinates[0].zip(expected_coordinates[0]).each { |a,b|
        # puts "#{a} = #{b}"
        expect(a[0]).to be_within(0.001).of(b[0])
        expect(a[1]).to be_within(0.001).of(b[1])
      }
    end

  end

  context 'bbox' do
    it 'can find stops by bounding box' do
      santa_clara = create(:stop, geometry: { type: 'Point', coordinates: [-121.936376, 37.352915] })
      mountain_view = create(:stop, geometry: { type: 'Point', coordinates: [-122.076327, 37.393879] })
      random = create(:stop, geometry: { type: 'Point', coordinates: [10.195312, 43.755225] })
      expect(Stop.geometry_within_bbox('-122.0,37.25,-121.75,37.5')).to match_array([santa_clara])
      expect(Stop.geometry_within_bbox('-122.25,37.25,-122.0,37.5')).to match_array([mountain_view])
    end

    it 'fails gracefully when ill-formed bounding box is provided' do
      expect { Stop.geometry_within_bbox('-122.25,37.25,-122.0') }.to raise_error(ArgumentError)
      expect { Stop.geometry_within_bbox() }.to raise_error(ArgumentError)
      expect { Stop.geometry_within_bbox([-122.25,37.25,-122.0]) }.to raise_error(ArgumentError)
    end
  end

  context '.geometry_centroid' do
    it 'can provide a centroid fallback when geometry is a polygon' do
      stop = create(:stop, geometry: geometry_polygon)
      centroid = stop.geometry_centroid
      expect(centroid.lon).to be_within(0.001).of(-122.13687551482836)
      expect(centroid.lat).to be_within(0.001).of(37.72253485209869)
    end
  end

  context '.geometry_for_centroid' do
    it 'geometry_reversegeo overrides geometry' do
      stop = create(:stop, geometry: geometry_polygon, geometry_reversegeo: geometry_point)
      expect(stop.geometry_for_centroid).to eq(stop[:geometry_reversegeo])
    end
  end

  context '.served_by_vehicle_types' do
    before(:each) do
      @route1 = create(:route, vehicle_type: 'metro')
      @route2 = create(:route, vehicle_type: 'bus')
      @route3 = create(:route, vehicle_type: 'tram')
      @stop1 = create(:stop)
      @stop2 = create(:stop)
      @stop3 = create(:stop)
      RouteServingStop.create!(route: @route1, stop: @stop1)
      RouteServingStop.create!(route: @route2, stop: @stop2)
      RouteServingStop.create!(route: @route3, stop: @stop3)
    end

    it 'accepts a string' do
      expect(Stop.served_by_vehicle_types('metro')).to match_array([@stop1])
    end

    it 'accepts an integer' do
      expect(Stop.served_by_vehicle_types(3)).to match_array([@stop2])
    end

    it 'accepts a mix of strings and integers' do
      expect(Stop.served_by_vehicle_types(['metro', 3])).to match_array([@stop1, @stop2])
    end

    it 'fails when invalid vehicle_type' do
      expect{ Stop.served_by_vehicle_types('unicycle') }.to raise_error(KeyError)
    end
  end

  context '.with_min_platforms' do
    before(:each) do
      @s1 = create(:stop)
      @s2 = create(:stop)
      @s2p1 = create(:stop_platform, parent_stop: @s2)
      @s3 = create(:stop)
      @s3p1 = create(:stop_platform, parent_stop: @s3)
      @s3p2 = create(:stop_platform, parent_stop: @s3)
    end

    it 'returns only Stops with StopPlatforms' do
      expect(Stop.with_min_platforms(1)).to match_array([@s2, @s3])
    end

    it 'returns minimum StopPlatforms' do
      expect(Stop.with_min_platforms(2)).to match_array([@s3])
    end

    it 'works with count' do
      # Handled in JSON pagination concern
      expect(Stop.with_min_platforms(1).count.size).to eq(2)
    end

    it 'works with min_egresses' do
      @s3e1 = create(:stop_egress, parent_stop: @s3)
      expect(Stop.with_min_platforms(1).with_min_egresses(1)).to eq([@s3])
    end
  end

  context '.with_min_egresses' do
    before(:each) do
      @s1 = create(:stop)
      @s2 = create(:stop)
      @s2e1 = create(:stop_egress, parent_stop: @s2)
      @s3 = create(:stop)
      @s3e1 = create(:stop_egress, parent_stop: @s3)
      @s3e2 = create(:stop_egress, parent_stop: @s3)
    end

    it 'returns only Stops with StopEgresses' do
      expect(Stop.with_min_egresses(1)).to match_array([@s2, @s3])
    end

    it 'returns minimum StopPlatforms' do
      expect(Stop.with_min_egresses(2)).to match_array([@s3])
    end

    it 'works with count' do
      # Handled in JSON pagination concern
      expect(Stop.with_min_egresses(1).count.size).to eq(2)
    end

    it 'works with min_platforms' do
      @s3p1 = create(:stop_platform, parent_stop: @s3)
      expect(Stop.with_min_platforms(1).with_min_egresses(1)).to eq([@s3])
    end
  end

  context 'served_by' do
    before(:each) do
      @bart = create(:operator, name: 'BART')
      @sfmta = create(:operator, name: 'SFMTA')
      @bart_route = create(:route, operator: @bart)
      @sfmta_route = create(:route, operator: @sfmta)
      @stop_with_both = create(:stop)
      @stop_with_sfmta = create(:stop)
      @stop_with_both.routes << [@bart_route, @sfmta_route]
      @stop_with_both.operators << [@bart, @sfmta]
      @stop_with_sfmta.routes << @sfmta_route
      @stop_with_sfmta.operators << @sfmta
    end

    it 'by operator' do
      expect(Stop.served_by([@sfmta])).to match_array([@stop_with_both, @stop_with_sfmta])
      expect(Stop.served_by([@sfmta.onestop_id])).to match_array([@stop_with_both, @stop_with_sfmta])
      expect(Stop.served_by([@bart])).to match_array([@stop_with_both])
      expect(Stop.served_by([@bart.onestop_id])).to match_array([@stop_with_both])
      expect(Stop.served_by([@sfmta.onestop_id, @bart])).to match_array([@stop_with_both, @stop_with_sfmta])
    end

    it 'by route' do
      expect(Stop.served_by([@sfmta_route])).to match_array([@stop_with_both, @stop_with_sfmta])
      expect(Stop.served_by([@sfmta_route.onestop_id])).to match_array([@stop_with_both, @stop_with_sfmta])
      expect(Stop.served_by([@bart_route])).to match_array([@stop_with_both])
      expect(Stop.served_by([@bart_route.onestop_id])).to match_array([@stop_with_both])
      expect(Stop.served_by([@sfmta_route.onestop_id, @bart_route])).to match_array([@stop_with_both, @stop_with_sfmta])
    end

    it 'by both operator and route' do
      expect(Stop.served_by([@sfmta_route.onestop_id, @bart])).to match_array([@stop_with_both, @stop_with_sfmta])
      expect(Stop.served_by([@sfmta_route, @bart.onestop_id])).to match_array([@stop_with_both, @stop_with_sfmta])
    end
  end

  context 'conflation' do
    it 'finds stops that have not been conflated since' do
      stop1 = create(:stop, last_conflated_at: 1.hours.ago)
      stop2 = create(:stop, last_conflated_at: 3.hours.ago)
      expect(Stop.last_conflated_before(2.hours.ago)).to match_array([stop2])
    end

    it '.re_conflate_with_osm' do
      stop1 = create(:stop, last_conflated_at: 3.hours.ago)
      expect {
        Stop.re_conflate_with_osm(2.hours.ago)
      }.to change(StopConflateWorker.jobs, :size).by(1)
    end

    # TODO: Broken mock
    # it 'handles case of stop returning a valid Tyr response, but no edges' do
    #   allow(Figaro.env).to receive(:tyr_auth_token) { 'fakeapikey' }
    #   stub_const('TyrService::BASE_URL', 'https://valhalla.mapzen.com')
    #   stub_const('TyrService::MAX_LOCATIONS_PER_REQUEST', 100)
    #   VCR.use_cassette('null_island_stop') do
    #     stop = create(:stop, geometry: { type: 'Point', coordinates: [0.0, 0.0] })
    #     expect(Sidekiq::Logging.logger).to receive(:info).with(/Tyr response for Stop #{stop.onestop_id} did not contain edges. Leaving osm_way_id./)
    #     Stop.conflate_with_osm([stop])
    #   end
    # end

    it '.conflate_with_osm' do
      #pending 'write some specs'
    end
  end

  context 'diff_against' do
    pending 'write some specs'
  end
end
