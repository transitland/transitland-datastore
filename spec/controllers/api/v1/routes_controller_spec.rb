describe Api::V1::RoutesController do
  before(:each) do
    @richmond_millbrae_route = create(
      :route,
      name: 'Richmond - Daly City/Millbrae',
      onestop_id: 'r-9q8y-richmond~dalycity~millbrae',
      wheelchair_accessible: 'all_trips',
      bikes_allowed: 'some_trips',
      geometry: {
        coordinates: [
          [[-122.353165,37.936887],[-122.317269,37.925655],[-122.2992715,37.9030588],[-122.283451,37.87404],[-122.268045,37.869867],[-122.26978,37.853024],[-122.267227,37.828415],[-122.269029,37.80787],[-122.271604,37.803664],[-122.2945822,37.80467476],[-122.396742,37.792976],[-122.401407,37.789256],[-122.406857,37.784991],[-122.413756,37.779528],[-122.419694,37.765062],[-122.418466,37.752254],[-122.434092,37.732921],[-122.4474142,37.72198087],[-122.4690807,37.70612055],[-122.466233,37.684638],[-122.444116,37.664174],[-122.416038,37.637753],[-122.38666,37.599787]],
          [[-122.4690807,37.70612055],[-122.4474142,37.72198087],[-122.434092,37.732921],[-122.418466,37.752254],[-122.419694,37.765062],[-122.413756,37.779528],[-122.406857,37.784991],[-122.401407,37.789256],[-122.396742,37.792976],[-122.2945822,37.80467476],[-122.271604,37.803664],[-122.269029,37.80787],[-122.267227,37.828415],[-122.26978,37.853024],[-122.268045,37.869867],[-122.283451,37.87404],[-122.2992715,37.9030588],[-122.317269,37.925655],[-122.353165,37.936887]]
        ],
        type: 'MultiLineString'
      }
    )
    point = Stop::GEOFACTORY.point(-122.38666,37.599787)
    millbrae = create(
      :stop,
      onestop_id: "s-9q8vzhbf8h-millbrae",
      name: "Millbrae",
      geometry: point.to_s,
    )
    rsp = create(:route_serving_stop, route_id: @richmond_millbrae_route.id, stop_id: millbrae.id)
  end

  describe 'GET index' do
    context 'as JSON' do
      it 'returns all current routes when no parameters provided' do
        get :index
        expect_json_types({ routes: :array }) # TODO: remove root node?
        expect_json({ routes: -> (routes) {
          expect(routes.length).to eq 1
        }})
      end

      context 'returns routes by identifier' do
        it 'when not found' do
          get :index, identifier: '19X'
          expect_json({ routes: -> (routes) {
            expect(routes.length).to eq 0
          }})
        end

        it 'when found' do
          get :index, identifier: 'Richmond - Daly City/Millbrae'
          expect_json({ routes: -> (routes) {
            expect(routes.length).to eq 1
          }})
        end
      end

      it 'returns route within a bounding box' do
        get :index, bbox: '-122.4228858947754,37.59043119366754,-122.34460830688478,37.62374937200642'
        expect_json({ routes: -> (routes) {
          expect(routes.first[:onestop_id]).to eq 'r-9q8y-richmond~dalycity~millbrae'
        }})
      end

      it 'returns no routes when no route stops in bounding box' do
        get :index, bbox: '-122.353165,37.936887,-122.2992715,37.9030588'
        expect_json({ routes: -> (routes) {
          expect(routes.length).to eq 0
        }})
      end

      context 'returns routes by vehicle type' do
        it 'by integer' do
          get :index, vehicle_type: @richmond_millbrae_route.vehicle_type_value
          expect_json({ routes: -> (routes) {
            expect(routes.length).to eq 1
          }})
        end

        it 'by string' do
          get :index, vehicle_type: @richmond_millbrae_route.vehicle_type
          expect_json({ routes: -> (routes) {
            expect(routes.length).to eq 1
          }})
        end
      end

      it 'returns routes operated by an Operator' do
        other_operator = create(:operator)
        other_route = create(:route, operator: other_operator)

        bart = create(:operator, name: 'BART', onestop_id: 'o-9q9-BART')
        @richmond_millbrae_route.update(operator: bart)

        get :index, operatedBy: 'o-9q9-BART'
        expect_json({ routes: -> (routes) {
          expect(routes.first[:onestop_id]).to eq 'r-9q8y-richmond~dalycity~millbrae'
        }})
      end

      it 'returns routes operated by multiple Operators' do
        other_operator = create(:operator)
        other_route = create(:route, operator: other_operator)

        bart = create(:operator, name: 'BART', onestop_id: 'o-9q9-BART')
        @richmond_millbrae_route.update(operator: bart)
        sfmuni = create(:operator, name: 'San Francisco Municipal Transportation Agency', onestop_id: 'o-9q8y-sfmta')
        muni_route = create(:route, operator: sfmuni)

        get :index, operatedBy: 'o-9q9-BART,o-9q8y-sfmta'
        expect_json({ routes: -> (routes) {
          expect(routes.map { |route| route[:onestop_id] } ).to eq [@richmond_millbrae_route.onestop_id, muni_route.onestop_id]
        }})
      end

      it 'returns routes serving stops' do
        stop1, stop2, stop3 = create_list(:stop, 3)
        route1, route2 = create_list(:route, 2)
        route1.routes_serving_stop.create!(stop: stop1)
        route2.routes_serving_stop.create!(stop: stop2)
        get :index, serves: stop1.onestop_id
        expect_json({ routes: -> (routes) {expect(routes.length).to eq 1}})
        get :index, serves: [stop1.onestop_id, stop2.onestop_id]
        expect_json({ routes: -> (routes) {expect(routes.length).to eq 2}})
        get :index, serves: [stop3.onestop_id]
        expect_json({ routes: -> (routes) {expect(routes.length).to eq 0}})
      end

      it 'returns routes traversing route stop patterns' do
        route1 = create(:route)
        route2 = create(:route)
        route_stop_pattern = create(:route_stop_pattern, route: route1)
        other_route_stop_pattern = create(:route_stop_pattern, route: route2)

        get :index, traverses: "#{route_stop_pattern.onestop_id},#{other_route_stop_pattern.onestop_id}"
        expect_json({ routes: -> (routes) {
          expect(routes.length).to eq 2
          expect(routes.map { |r| r[:onestop_id] }).to match_array([route1.onestop_id, route2.onestop_id])
        }})
      end

      it 'returns no routes when none traversing route stop patterns' do
        other_route_stop_pattern = create(:route_stop_pattern)

        get :index, traverses: 'r-9q8y-test-45cad3-46d384'
        expect_json({ routes: -> (routes) {
          expect(routes.length).to eq 0
        }})
      end

      it 'returns all routes with a defined color' do
        get :index, color: 'true'
        expect_json({ routes: -> (routes) {
          expect(routes.length).to eq 0
        }})
      end

      it 'returns all routes with a specified color' do
        Route.first.update(color: 'CCEEFF')
        get :index, color: 'cceeff'
        expect_json({ routes: -> (routes) {
          expect(routes.length).to eq 1
        }})
      end

      context 'wheelchair_accessible' do
        it 'include' do
          get :index, wheelchair_accessible: "all_trips"
          expect_json({ routes: -> (routes) {
            expect(routes.first[:onestop_id]).to eq @richmond_millbrae_route.onestop_id
          }})
        end

        it 'exclude' do
          get :index, wheelchair_accessible: "unknown"
          expect_json({ routes: -> (routes) {
            expect(routes.length).to eq 0
          }})
        end
      end

      context 'bikes_allowed' do
        it 'include' do
          get :index, bikes_allowed: "some_trips"
          expect_json({ routes: -> (routes) {
            expect(routes.first[:onestop_id]).to eq @richmond_millbrae_route.onestop_id
          }})
        end

        it 'exclude' do
          get :index, bikes_allowed: "unknown"
          expect_json({ routes: -> (routes) {
            expect(routes.length).to eq 0
          }})
        end
      end
    end

    context 'as CSV' do
      before(:each) do
        @sfmta = create(:operator, geometry: 'POINT(-122.395644 37.722413)', name: 'SFMTA')
        @richmond_millbrae_route.update(operator: @sfmta)
      end
      it 'should return a CSV file for download' do
        get :index, format: :csv
        expect(response.headers['Content-Type']).to eq 'text/csv'
        expect(response.headers['Content-Disposition']).to eq 'attachment; filename=routes.csv'
      end

      it 'should include column headers and row values' do
        get :index, format: :csv #, identifier: 'Richmond - Daly City/Millbrae'
        expect(response.body.lines.count).to eq 2
        expect(response.body).to start_with(Route.csv_column_names.join(','))
        expect(response.body).to include([@richmond_millbrae_route.onestop_id, @richmond_millbrae_route.name, @sfmta.name, @sfmta.onestop_id].join(','))
      end
    end

    context 'as GeoJSON' do
      it 'should return GeoJSON for all routes' do
        get :index, format: :geojson
        expect_json({
          type: 'FeatureCollection',
          features: -> (features) {
            expect(features.first[:properties][:onestop_id]).to eq 'r-9q8y-richmond~dalycity~millbrae'
            # expect(features.first[:properties][:title]).to eq 'Richmond - Daly City/Millbrae'
          }
        })
      end
    end
  end

  describe 'GET show' do
    context 'as JSON' do
      it 'returns routes by OnestopID' do
        get :show, id: 'r-9q8y-richmond~dalycity~millbrae'
        expect_json_types({
          onestop_id: :string,
          geometry: :object,
          name: :string,
          created_at: :date,
          updated_at: :date,
          stops_served_by_route: :array
        })
        expect_json({ onestop_id: -> (onestop_id) {
          expect(onestop_id).to eq 'r-9q8y-richmond~dalycity~millbrae'
        }})
      end

      it 'returns a 404 when not found' do
        get :show, id: 'ntd9015-2053'
        expect(response.status).to eq 404
      end
    end

    context 'as GeoJSON' do
      it 'should return GeoJSON for a single route' do
        get :show, id: 'r-9q8y-richmond~dalycity~millbrae', format: :geojson
        expect_json({
          type: 'Feature',
          properties: -> (properties) {
            expect(properties[:onestop_id]).to eq 'r-9q8y-richmond~dalycity~millbrae'
            # expect(properties[:title]).to eq 'Richmond - Daly City/Millbrae'
          }
        })
      end
    end
  end
end
