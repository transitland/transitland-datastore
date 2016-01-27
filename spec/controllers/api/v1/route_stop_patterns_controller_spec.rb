describe Api::V1::RouteStopPatternsController do

  let(:stop_1) { create(:stop,
    onestop_id: "s-9q8yw8y448-bayshorecaltrainstation",
    geometry: Stop::GEOFACTORY.point(-122.401811, 37.706675).to_s
  )}
  let(:stop_2) { create(:stop,
    onestop_id: "s-9q8yyugptw-sanfranciscocaltrainstation",
    geometry: Stop::GEOFACTORY.point(-122.394935, 37.776348).to_s
  )}

  before(:each) do
    @bullet_route = create(
      :route,
      name: 'Bullet',
      onestop_id: 'r-9q9j-bullet'
    )
    points = [stop_1.geometry[:coordinates], stop_2.geometry[:coordinates]]
    geom = RouteStopPattern::GEOFACTORY.line_string(
      points.map {|lon, lat| RouteStopPattern::GEOFACTORY.point(lon, lat)}
    )
    sp = [stop_1.onestop_id, stop_2.onestop_id]
    @rsp = create(:route_stop_pattern,
      stop_pattern: sp,
      geometry: geom,
      onestop_id: 'r-9q9j-bullet-c2e44f-8c801d',
      route: @bullet_route,
      trips: ['trip1','trip2']
    )
  end


  describe 'GET index' do
    context 'as JSON' do
      it 'returns all current route_stop_patterns when no parameters provided' do
        get :index
        expect_json_types({ route_stop_patterns: :array })
        expect_json({ route_stop_patterns: -> (route_stop_patterns) {
          expect(route_stop_patterns.length).to eq 1
        }})
      end
    end

    context 'returns route_stop_patterns by trips' do
      it 'when not found' do
        get :index, trips: 'trip3'
        expect_json({ route_stop_patterns: -> (route_stop_patterns) {
          expect(route_stop_patterns.length).to eq 0
        }})
      end

      it 'when found' do
        get :index, trips: 'trip2,trip1'
        expect_json({ route_stop_patterns: -> (route_stop_patterns) {
          expect(route_stop_patterns.length).to eq 1
        }})
      end
    end

    context 'returns route_stop_patterns by stops visited' do
      it 'when not found' do
        get :index, stops_visited: 's-9q8yw8y448-testing'
        expect_json({ route_stop_patterns: -> (route_stop_patterns) {
          expect(route_stop_patterns.length).to eq 0
        }})
      end

      it 'when found' do
        get :index, stops_visited: 's-9q8yw8y448-bayshorecaltrainstation,s-9q8yyugptw-sanfranciscocaltrainstation'
        expect_json({ route_stop_patterns: -> (route_stop_patterns) {
          expect(route_stop_patterns.length).to eq 1
        }})
      end
    end

    context 'returns route_stop_patterns by route traversed by' do
      it 'when not found' do
        get :index, traversed_by: 'r-9q9j-test'
        expect(response.status).to eq 404
      end

      it 'when found' do
        get :index, traversed_by: 'r-9q9j-bullet'
        expect_json({ route_stop_patterns: -> (route_stop_patterns) {
          expect(route_stop_patterns.length).to eq 1
        }})
      end
    end

  end
end
