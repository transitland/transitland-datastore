describe Api::V1::StopsController do
  before(:each) do
    @glen_park = create(:stop, geometry: 'POINT(-122.433416 37.732525)', name: 'Glen Park', identifiers: ['SFMTA-GP'])
    @bosworth_diamond = create(:stop, geometry: 'POINT(-122.434011 37.733595)', name: 'Bosworth + Diamond')
    @metro_embarcadero = create(:stop, geometry: 'POINT(-122.396431 37.793152)', name: 'Metro Embarcadero')
    @gilman_paul_3rd = create(:stop, geometry: 'POINT(-122.395644 37.722413)', name: 'Gilman + Paul + 3rd St.')
  end

  describe 'GET index' do
    context 'as JSON' do
      it 'returns all current stops when no parameters provided' do
        get :index
        expect_json_types({ stops: :array }) # TODO: remove root node?
        expect_json({ stops: -> (stops) {
          expect(stops.length).to eq 4
        }})
      end

      it 'returns the appropriate stop when identifier provided' do
        get :index, identifier: 'SFMTA-GP'
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

      context 'returns stop by servedBy' do
        before(:each) do
          @bart = create(:operator, name: 'BART')
          @sfmta = create(:operator, name: 'SFMTA')
          @bart_route = create(:route, operator: @bart)
          @sfmta_route = create(:route, operator: @sfmta)
          @metro_embarcadero.routes << [@bart_route, @sfmta_route]
          @metro_embarcadero.operators << [@bart, @sfmta]
          @gilman_paul_3rd.routes << @sfmta_route
          @gilman_paul_3rd.operators << @sfmta
        end

        it 'with an operator Onestop ID' do
          get :index, servedBy: @bart.onestop_id
          expect_json({ stops: -> (stops) {
            expect(stops.map { |stop| stop[:onestop_id] }).to match_array([@metro_embarcadero.onestop_id])
          }})
        end

        it 'with an operator and a route Onestop ID' do
          get :index, servedBy: "#{@bart.onestop_id},#{@sfmta_route.onestop_id}"
          expect_json({ stops: -> (stops) {
            expect(stops.map { |stop| stop[:onestop_id] }).to match_array([@metro_embarcadero, @gilman_paul_3rd].map(&:onestop_id))
          }})
        end
      end

      context 'returns stops by tags' do
        before(:each) do
          @glen_park.update(tags: { wheelchair_accessible: 'yes' })
          @gilman_paul_3rd.update(tags: { wheelchair_accessible: 'no' })
        end

        it 'with a tag key' do
          get :index, tag_key: 'wheelchair_accessible'
          expect_json({ stops: -> (stops) {
            expect(stops.map { |stop| stop[:onestop_id] }).to match_array([@glen_park.onestop_id, @gilman_paul_3rd.onestop_id])
          }})
        end

        it 'with a tag key and value' do
          get :index, tag_key: 'wheelchair_accessible', tag_value: 'yes'
          expect_json({ stops: -> (stops) {
            expect(stops.map { |stop| stop[:onestop_id] }).to match_array([@glen_park.onestop_id])
          }})
        end
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

    context 'as CSV' do
      before(:each) do
        @sfmta = create(:operator, geometry: 'POINT(-122.395644 37.722413)', name: 'SFMTA')
        @metro_embarcadero.operators << @sfmta
      end
      it 'should return a CSV file for download' do
        get :index, format: :csv
        expect(response.headers['Content-Type']).to eq 'text/csv'
        expect(response.headers['Content-Disposition']).to eq 'attachment; filename=stops.csv'
      end

      it 'should include column headers and row values' do
        get :index, format: :csv, bbox: '-122.4131,37.7136,-122.3789,37.8065'
        expect(response.body.lines.count).to eq 3
        expect(response.body).to start_with('Onestop ID,Name,Operators serving stop (names),Operators serving stop (Onestop IDs),Latitude (centroid),Longitude (centroid)')
        expect(response.body).to include("#{@metro_embarcadero.onestop_id},#{@metro_embarcadero.name},#{@sfmta.name},#{@sfmta.onestop_id},#{@metro_embarcadero.geometry(as: :wkt).lat},#{@metro_embarcadero.geometry(as: :wkt).lon}")
      end
    end
  end

  describe 'GET show' do
    it 'returns stops by Onestop ID' do
      get :show, id: @metro_embarcadero.onestop_id
      expect_json_types('stop',
        onestop_id: :string,
        geometry: :object,
        name: :string,
        created_at: :date,
        updated_at: :date
      )
      expect_json('stop', onestop_id: -> (onestop_id) {
        expect(onestop_id).to eq @metro_embarcadero.onestop_id
      })
    end

    it 'returns a 404 when not found' do
      get :show, id: 'ntd9015-2053'
      expect(response.status).to eq 404
    end
  end
end
