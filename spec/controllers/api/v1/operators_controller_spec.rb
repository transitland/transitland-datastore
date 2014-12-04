describe Api::V1::OperatorsController do
  before(:each) do
    @vta = create(:operator, name: 'Santa Clara Valley Transportation Agency', geometry: 'POINT(-121.891583 37.336063)')
    @sfmta = create(:operator, name: 'SFMTA', geometry: 'POINT(-122.418611 37.774870)')

    @vta.identifiers.create(identifier: 'VTA')

    @glen_park = create(:stop, geometry: 'POINT(-122.433416 37.732525)', name: 'Glen Park' )

    @sfmta.stops << @glen_park
  end

  describe 'GET index' do
    context 'as JSON' do
      it 'returns all operators when no parameters provided' do
        get :index
        expect_json_types({ operators: :array }) # TODO: remove root node?
        expect_json({ operators: -> (operators) {
          expect(operators.length).to eq 2
        }})
      end

      it 'returns the appropriate operator when identifier provided' do
        get :index, identifier: 'VTA'
        expect_json({ operators: -> (operators) {
          expect(operators.first[:onestop_id]).to eq @vta.onestop_id
        }})
      end

      it 'returns operators within a circular radius when lat/lon/r provided' do
        get :index, lat: 37.732520, lon: -122.433415, r: 10_000
        expect_json({ operators: -> (operators) {
          expect(operators.first[:onestop_id]).to eq @sfmta.onestop_id
        }})
      end

      it 'returns operator within a bounding box' do
        get :index, bbox: '-122.4131,37.7136,-122.3789,37.8065'
        expect_json({ operators: -> (operators) {
          expect(operators.first[:onestop_id]).to eq @sfmta.onestop_id
        }})
      end
    end

    context 'as GeoJSON' do
      it 'returns operator within a bounding box' do
        get :index, format: :geojson, bbox: '-122.0883,37.198,-121.8191,37.54804'
        expect_json({
          type: 'FeatureCollection',
          features: -> (features) { expect(features.first[:id]).to eq @vta.onestop_id }
        })
      end
    end
  end

  describe 'GET show' do
    context 'as JSON' do
      it 'returns operators by OnestopId' do
        get :show, id: @vta.onestop_id
        expect_json_types({
          onestop_id: :string,
          geometry: :string,
          name: :string,
          created_at: :date,
          updated_at: :date
        })
        expect_json({ onestop_id: -> (onestop_id) {
          expect(onestop_id).to eq @vta.onestop_id
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
end
