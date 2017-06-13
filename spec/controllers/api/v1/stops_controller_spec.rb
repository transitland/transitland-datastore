describe Api::V1::StopsController do
  before(:each) do
    @glen_park = create(:stop, geometry: 'POINT(-122.433416 37.732525)', name: 'Glen Park')
    @bosworth_diamond = create(:stop, geometry: 'POINT(-122.434011 37.733595)', name: 'Bosworth + Diamond')
    @metro_embarcadero = create(:stop, geometry: 'POINT(-122.396431 37.793152)', name: 'Metro Embarcadero')
    @gilman_paul_3rd = create(:stop, geometry: 'POINT(-122.395644 37.722413)', name: 'Gilman + Paul + 3rd St.')
  end

  describe 'GET index' do
    context 'as JSON' do
      it 'returns stops with wheelchair_boarding' do
        stop_true = create(:stop, wheelchair_boarding: true)
        stop_false = create(:stop, wheelchair_boarding: false)
        get :index, wheelchair_boarding: 'true'
        expect_json({ stops: -> (stops) {
            expect(stops.first[:onestop_id]).to eq stop_true.onestop_id
            expect(stops.count).to eq 1
            expect(stops.first[:wheelchair_boarding]).to be true
        }})
      end

      context 'served_by_vehicle_types' do
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

        it 'accepts a mix of strings and integers' do
          get :index, served_by_vehicle_types: ['metro', 3]
          expect_json({ stops: -> (stops) {
            expect(stops.map { |stop| stop[:onestop_id] }).to match_array([@stop1.onestop_id, @stop2.onestop_id])
          }})
        end
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
    end
  end
end
