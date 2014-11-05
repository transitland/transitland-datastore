describe Api::V1::StopsController do
  before(:each) do
    @glen_park = create(:stop, geometry: 'POINT(-122.433416 37.732525)')
    @bosworth_diamond = create(:stop, geometry: 'POINT(-122.434011 37.733595)')
    @metro_embarcadero = create(:stop, geometry: 'POINT(-122.396431 37.793152)')
    @gilman_paul_3rd = create(:stop, geometry: 'POINT(-122.395644 37.722413)')
  end

  describe 'GET index' do
    context 'as JSON' do
      it 'returns all stops when no parameters provided' do
        get :index
        expect_json_types({ stops: :array }) # TODO: remove root node?
        expect_json({ stops: -> (stops) {
          expect(stops.length).to eq 4
        }})
      end

      it 'returns the appropriate stop when identifier provided' do
        create(:stop_identifier, stop: @glen_park)
        get :index, identifier: @glen_park.stop_identifiers.first.identifier
        expect_json({ stops: -> (stops) {
          expect(stops.first[:onestop_id]).to eq @glen_park.onestop_id
        }})
      end

      it 'returns stops within a circular radius when lat/lon/r provided' do
        get :index, lat: 37.732520, lon: -122.433415, r: 500
        expect_json({ stops: -> (stops) {
          expect(stops.map { |stop| stop[:onestop_id] }).to match_array([@glen_park, @bosworth_diamond].map(&:onestop_id))
        }})
      end

      it 'returns stop within a bounding box' do
        get :index, bbox: '-122.4131,37.7136,-122.3789,37.8065'
        expect_json({ stops: -> (stops) {
          expect(stops.map { |stop| stop[:onestop_id] }).to match_array([@metro_embarcadero, @gilman_paul_3rd].map(&:onestop_id))
        }})
      end
    end

    context 'as GeoJSON' do
      it 'returns stop within a bounding box' do
        get :index, format: :geojson, bbox: '-122.4131,37.7136,-122.3789,37.8065'
        expect_json({
          type: 'FeatureCollection',
          features: -> (features) {
            expect(features.map { |feature| feature[:id] }).to match_array([@metro_embarcadero, @gilman_paul_3rd].map(&:onestop_id))
          }
        })
      end
    end
  end

  describe 'GET show' do
    it 'returns stops by OnestopID' do
      get :show, id: @metro_embarcadero.onestop_id
      expect_json_types({
        onestop_id: :string,
        geometry: :string,
        name: :string,
        created_at: :date,
        updated_at: :date
      })
      expect_json({ onestop_id: -> (onestop_id) {
        expect(onestop_id).to eq @metro_embarcadero.onestop_id
      }})
    end

    it 'returns a 404 when not found' do
      get :show, id: 'ntd9015-2053'
      expect(response.status).to eq 404
    end
  end

  describe 'POST create' do
    it 'will work when given valid input' do
      expect {
        post :create, stop: { onestop_id: 'ntd53-Blah'}
      }.to change{Stop.count}.by(1)
    end

    it 'will fail gracefully when given no input' do
      expect {
        post :create
      }.to change{Stop.count}.by(0)
      expect(response.status).to eq 400
      expect_json({ error: -> (error) {
        expect(error).to eq 'param is missing or the value is empty: stop'
      }})
    end

    it 'will fail gracefully when given invalid input' do
      expect {
        post :create, stop: { blah: 'whah'}
      }.to change{Stop.count}.by(0)
      expect(response.status).to eq 400
      expect_json({ error: -> (error) {
        expect(error).to eq 'unknown attribute: blah'
      }})
    end
  end

  describe 'PUT update' do
    it 'will work when given valid input' do
      put :update, id: @glen_park.onestop_id, stop: { tags: { indoor: true } }
      expect(@glen_park.reload.tags['indoor']).to eq 'true'
    end

    it 'will fail gracefully when given invalid input' do
      put :update, id: @glen_park.onestop_id, stop: { taags: { indoor: true } }
      expect(response.status).to eq 400
      expect_json({ error: -> (error) {
        expect(error).to eq 'unknown attribute: taags'
      }})
    end
  end

  describe 'DELETE destroy' do
    it 'will work when given valid ID' do
      expect {
        delete :destroy, id: @glen_park.onestop_id
      }.to change{Stop.count}.by(-1)
    end
  end
end
