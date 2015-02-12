describe Api::V1::OnestopIdController do
  before(:each) do
    @glen_park = create(:stop, geometry: 'POINT(-122.433416 37.732525)', name: 'Glen Park')
    @bosworth_diamond = create(:stop, geometry: 'POINT(-122.434011 37.733595)', name: 'Bosworth + Diamond')
    @metro_embarcadero = create(:stop, geometry: 'POINT(-122.396431 37.793152)', name: 'Metro Embarcadero')
    @gilman_paul_3rd = create(:stop, geometry: 'POINT(-122.395644 37.722413)', name: 'Gilman + Paul + 3rd St.')

    @sfmta = create(:operator, geometry: 'POINT(-122.395644 37.722413)', name: 'SFMTA')
  end

  describe 'GET show' do
    it 'will return an Operator' do
      get :show, onestop_id: @sfmta.onestop_id
      expect_json({ onestop_id: -> (onestop_id) {
        expect(onestop_id).to eq @sfmta.onestop_id
      }})
    end

    it 'will return a Stop' do
      get :show, onestop_id: @metro_embarcadero.onestop_id
      expect_json({ onestop_id: -> (onestop_id) {
        expect(onestop_id).to eq @metro_embarcadero.onestop_id
      }})
    end
  end
end
