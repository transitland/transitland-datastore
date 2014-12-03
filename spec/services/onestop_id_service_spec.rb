describe OnestopIdService do
  before(:each) do
    @glen_park = create(:stop, geometry: 'POINT(-122.433416 37.732525)', name: 'Glen Park' )
    @bosworth_diamond = create(:stop, geometry: 'POINT(-122.434011 37.733595)', name: 'Bosworth + Diamond')
    @metro_embarcadero = create(:stop, geometry: 'POINT(-122.396431 37.793152)', name: 'Metro Embarcadero')
    @gilman_paul_3rd = create(:stop, geometry: 'POINT(-122.395644 37.722413)', name: 'Gilman + Paul + 3rd St.')

    @sfmta = create(:operator, geometry: 'POINT(-122.395644 37.722413)', name: 'SFMTA')
  end

  context 'find!' do
    it 'a Stop' do
      found_bosworth_diamond = OnestopIdService.find!(@bosworth_diamond.onestop_id)
      expect(found_bosworth_diamond.id).to eq @bosworth_diamond.id
    end

    it 'an Operator' do
      found_sfmta = OnestopIdService.find!(@sfmta.onestop_id)
      expect(found_sfmta.id).to eq @sfmta.id
    end

    it 'will throw an exception when nothing found with that OnestopID' do
      expect {
        OnestopIdService.find!('s-b3-FakeSt')
      }.to raise_error ActiveRecord::RecordNotFound
    end
  end
end
