describe Api::V1::RoutesController do
  before(:each) do
    @richmond_millbrae_route = create(
      :route,
      name: 'Richmond - Daly City/Millbrae',
      onestop_id: 'r-9q8y-richmond~dalycity~millbrae',
      geometry: {
        coordinates: [
          [[-122.353165,37.936887],[-122.317269,37.925655],[-122.2992715,37.9030588],[-122.283451,37.87404],[-122.268045,37.869867],[-122.26978,37.853024],[-122.267227,37.828415],[-122.269029,37.80787],[-122.271604,37.803664],[-122.2945822,37.80467476],[-122.396742,37.792976],[-122.401407,37.789256],[-122.406857,37.784991],[-122.413756,37.779528],[-122.419694,37.765062],[-122.418466,37.752254],[-122.434092,37.732921],[-122.4474142,37.72198087],[-122.4690807,37.70612055],[-122.466233,37.684638],[-122.444116,37.664174],[-122.416038,37.637753],[-122.38666,37.599787]],
          [[-122.4690807,37.70612055],[-122.4474142,37.72198087],[-122.434092,37.732921],[-122.418466,37.752254],[-122.419694,37.765062],[-122.413756,37.779528],[-122.406857,37.784991],[-122.401407,37.789256],[-122.396742,37.792976],[-122.2945822,37.80467476],[-122.271604,37.803664],[-122.269029,37.80787],[-122.267227,37.828415],[-122.26978,37.853024],[-122.268045,37.869867],[-122.283451,37.87404],[-122.2992715,37.9030588],[-122.317269,37.925655],[-122.353165,37.936887]]
        ],
        type: 'MultiLineString'
      }
    )
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

      it 'returns no routes when none in bounding box' do
        get :index, bbox: '-122.25783348083498,37.61280361684656,-122.17955589294435,37.64611177340781'
        expect_json({ routes: -> (routes) {
          expect(routes.length).to eq 0
        }})
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
  end

  describe 'GET show' do
    it 'returns route by Onestop ID' do
      get :show, id: 'r-9q8y-richmond~dalycity~millbrae'
      expect_json_types('route',
        onestop_id: :string,
        geometry: :object,
        name: :string,
        created_at: :date,
        updated_at: :date
      )
      expect_json('route', onestop_id: -> (onestop_id) {
        expect(onestop_id).to eq 'r-9q8y-richmond~dalycity~millbrae'
      })
    end

    it 'returns a 404 when not found' do
      get :show, id: 'ntd9015-2053'
      expect(response.status).to eq 404
    end
  end
end
