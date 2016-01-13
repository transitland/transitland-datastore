describe Api::V1::RouteStopPatternsController do

  before(:each) do
    create(:stop,
      onestop_id: "s-9q8yw8y448-bayshorecaltrainstation",
      geometry: point = Stop::GEOFACTORY.point(-122.401811, 37.706675).to_s
    )
    create(:stop,
      onestop_id: "s-9q8yyugptw-sanfranciscocaltrainstation",
      geometry: point = Stop::GEOFACTORY.point(-122.394935, 37.776348).to_s
    )
    @bullet_route = create(
      :route,
      name: 'Bullet',
      onestop_id: 'r-9q9j-bullet'
    )
    points = [[-122.401811, 37.706675],[-122.394935, 37.776348]]
    geom = RouteStopPattern::GEOFACTORY.line_string(
      points.map {|lon, lat| RouteStopPattern::GEOFACTORY.point(lon, lat)}
    )
    sp = ["s-9q8yw8y448-bayshorecaltrainstation", "s-9q8yyugptw-sanfranciscocaltrainstation"]
    @rsp = create(:route_stop_pattern, stop_pattern: sp, geometry: geom, onestop_id: 'r-9q9j-bullet-S1-G1')
    @rsp.route = @bullet_route
  end


  describe 'GET index' do
    context 'as JSON' do
      it 'returns all current route_stop_patterns when no parameters provided' do
        get :index
        expect_json_types({ route_stop_patterns: :array })
        expect_json({ route_stop_patterns: -> (route_stop_patterns) {
          expect(routes.length).to eq 1
        }})
      end
    end
  end
end
