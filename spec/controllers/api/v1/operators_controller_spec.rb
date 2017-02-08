describe Api::V1::OperatorsController do
  let(:vta) {
    create(:operator,
      name: 'Santa Clara Valley Transportation Agency',
      geometry: { type: 'Polygon', coordinates:[[[-121.57063369100001,36.974922178],[-121.98392082799998,37.222231291999975],[-122.030939181,37.259406422],[-122.130937923,37.361408525999984],[-122.14999058399997,37.39545061899999],[-122.173638697,37.44055680899999],[-122.17356866899998,37.443449786999984],[-121.97594900000001,37.557287999999964],[-121.953170709,37.558388155999985],[-121.92699421000002,37.542184637],[-121.923956233,37.54013896899999],[-121.631097271,37.14884923099999],[-121.55177065999997,37.00582961999998],[-121.54902915,37.00006636],[-121.57063369100001,36.974922178]]] },
      tags: { agency_url: 'http://www.vta.org'},
      identifiers: ['VTA']
    )
  }
  let(:sfmta) {
    create(:operator, name: 'SFMTA', geometry: { type: 'Polygon', coordinates: [[[-122.461315,37.705978999999985],[-122.4690807,37.70612055],[-122.48498,37.70913],[-122.48529399999998,37.70931199999997],[-122.49765999999997,37.71676999999999],[-122.499913,37.71873799999998],[-122.500028,37.71899599999998],[-122.50682100000002,37.735481999999976],[-122.53867,37.83238],[-122.50214,37.836442999999996],[-122.48383,37.83591999999997],[-122.37347699999998,37.829819999999984],[-122.371964,37.82831099999999],[-122.36633000000002,37.82000099999998],[-122.365447,37.727920000000005],[-122.39283599999999,37.70980399999997],[-122.39422000000002,37.70897999999998],[-122.413084,37.706295999999995],[-122.461315,37.705978999999985]]]})
  }
  let(:glen_park) {
    create(:stop, geometry: 'POINT(-122.433416 37.732525)', name: 'Glen Park' )
  }

  describe 'GET index' do
    before(:each) do
      vta.touch
      sfmta.touch
      sfmta.stops << glen_park
    end

    context 'as JSON' do
      it 'returns all current operators when no parameters provided' do
        get :index
        expect_json_types({ operators: :array }) # TODO: remove root node?
        expect_json({ operators: -> (operators) {
          expect(operators.length).to eq 2
        }})
      end

      it 'filters by name' do
        operators = create_list(:operator, 3)
        operator = create(:operator, name: 'Test 123')
        get :index, name: operator.name
        expect_json({ operators: -> (operators) {
          expect(operators.first[:onestop_id]).to eq operator.onestop_id
          expect(operators.count).to eq 1
        }})
      end

      it 'filters by name, case insensitive' do
        operator = create(:operator, name: 'TEST')
        get :index, name: operator.name.downcase
        expect_json({ operators: -> (operators) {
          expect(operators.first[:onestop_id]).to eq operator.onestop_id
          expect(operators.count).to eq 1
        }})
      end

      it 'filters by short_name' do
        operators = create_list(:operator, 3)
        operator = create(:operator, short_name: 'Test 123')
        get :index, short_name: operator.short_name
        expect_json({ operators: -> (operators) {
          expect(operators.first[:onestop_id]).to eq operator.onestop_id
          expect(operators.count).to eq 1
        }})
      end

      it 'returns the appropriate operator when identifier provided' do
        get :index, identifier: 'VTA'
        expect_json({ operators: -> (operators) {
          expect(operators.first[:onestop_id]).to eq vta.onestop_id
        }})
      end

      it 'returns operators within a circular radius when lat/lon/r provided' do
        get :index, lat: 37.732520, lon: -122.433415, r: 10_000
        expect_json({ operators: -> (operators) {
          expect(operators.first[:onestop_id]).to eq sfmta.onestop_id
        }})
      end

      it 'returns operator within a bounding box' do
        get :index, bbox: '-122.4131,37.7136,-122.3789,37.8065'
        expect_json({ operators: -> (operators) {
          expect(operators.first[:onestop_id]).to eq sfmta.onestop_id
        }})
      end

      it 'returns the appropriate operator when Onestop ID provided' do
        get :index, onestop_id: sfmta.onestop_id
        expect_json({ operators: -> (operators) {
          expect(operators.first[:onestop_id]).to eq sfmta.onestop_id
          expect(operators.count).to eq 1
        }})
      end
    end

    context 'as GeoJSON' do
      it 'returns operator within a bounding box' do
        get :index, format: :geojson, bbox: '-122.0883,37.198,-121.8191,37.54804'
        expect_json({
          type: 'FeatureCollection',
          features: -> (features) { expect(features.first[:id]).to eq vta.onestop_id }
        })
      end
    end

    context 'as CSV' do
      it 'should return a CSV file for download' do
        get :index, format: :csv
        expect(response.headers['Content-Type']).to eq 'text/csv'
        expect(response.headers['Content-Disposition']).to eq 'attachment; filename=operators.csv'
      end

      it 'should include column headers and row values' do
        get :index, format: :csv, bbox: '-122.0883,37.198,-121.8191,37.54804'
        expect(response.body.lines.count).to eq 2
        expect(response.body).to start_with(Operator.csv_column_names.join(','))
        expect(response.body).to include([vta.onestop_id, vta.name, vta.tags[:agency_url]].join(','))
      end
    end
  end

  describe 'GET show' do
    context 'as JSON' do
      it 'returns operators by Onestop ID' do
        get :show, id: vta.onestop_id
        expect_json_types({
          onestop_id: :string,
          geometry: :object,
          name: :string,
          created_at: :date,
          updated_at: :date
        })
        expect_json({ onestop_id: -> (onestop_id) {
          expect(onestop_id).to eq vta.onestop_id
        }})
      end

      it 'returns a 404 when not found' do
        get :show, id: 'ntd9015'
        expect(response.status).to eq 404
      end
    end

    context 'as GeoJSON' do
      pending 'TODO: write this functionality'
    end
  end

  describe 'GET aggregate' do
    before(:each) do
      Rails.cache.clear
      create(:operator, country: 'US', state: 'US-CA', metro: 'San Francisco Bay Area', timezone: 'America/Los_Angeles')
      create(:operator, country: 'US', state: 'US-CA', metro: 'San Francisco Bay Area', timezone: 'America/Los_Angeles')
      create(:operator, country: 'US', state: 'US-CA', metro: 'Los Angeles', timezone: 'America/Los_Angeles')
    end

    it 'returns a list of all countries with counts for each' do
      get :aggregate
      expect_json('country.US.count', 3)
    end

    it 'returns a list of all states with counts for each' do
      get :aggregate
      expect_json('state.US-CA.count', 3)
    end

    it 'returns a list of all metros with counts for each' do
      get :aggregate
      expect_json('metro.San Francisco Bay Area.count', 2)
    end

    it 'returns a list of all timezones with counts for each' do
      get :aggregate
      expect_json(timezone: -> (timezone) {
        expect(timezone).to eq({
          :'America/Los_Angeles' => {
            count: 3,
            query_url: 'http://localhost:3000/api/v1/operators?timezone=America%2FLos_Angeles'
          }
        })
      })
    end

    it 'returns a list of all tags with counts and values for each' do
      Operator.first.update(tags: {
        fast: 'always',
        free: 'true'
      })
      Operator.second.update(tags: {
        fast: 'never'
      })
      Operator.third.update(tags: {
        allows_food: 'false'
      })
      get :aggregate
      expect_json('tags.fast.count', 2)
      expect_json('tags.fast.values', ['always', 'never'])
      expect_json('tags.free.count', 1)
      expect_json('tags.free.values', ['true'])
      expect_json('tags.allows_food.count', 1)
      expect_json('tags.allows_food.values', ['false'])
    end
  end
end
