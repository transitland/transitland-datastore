describe OnestopId do
  it 'fails gracefully when given an invalid geometry' do
    expect {
      OnestopId.new('Retiro Station', '-58.374722 -34.591389')
    }.to raise_error(ArgumentError)

    expect {
      OnestopId.new('Retiro Station', [-58.374722,-34.591389])
    }.to raise_error(ArgumentError)
  end

  context 'create' do
    it 'filters geohashes' do
      expect(
        OnestopId.new(entity_prefix: 's', geohash: 'a9q9', name: 'test').to_s
      ).to eq('s-9q9-test')
    end
    it 'filters names' do
      expect(
        OnestopId.new(entity_prefix: 's', geohash: '9q9', name: 'Foo Bar!').to_s
      ).to eq('s-9q9-foobar')
    end
    it 'filters names at' do
      expect(
        OnestopId.new(entity_prefix: 's', geohash: '9q9', name: 'foo@bar').to_s
      ).to eq('s-9q9-foo~bar')
    end
  end

  context 'validation' do
    it 'must not be blank' do
      is_a_valid_onestop_id, errors = OnestopId.validate_onestop_id_string('')
      expect(is_a_valid_onestop_id).to be false
      expect(errors).to include 'must not be blank'
    end
    it 'must start with "s-" as its 1st component' do
      is_a_valid_onestop_id, errors = OnestopId.validate_onestop_id_string('69y7pwu-RetSta', expected_entity_type: 'stop')
      expect(is_a_valid_onestop_id).to be false
      expect(errors).to include 'must start with "s" as its 1st component'
    end

    it 'must include 3 components separated by hyphens ("-")' do
      is_a_valid_onestop_id, errors = OnestopId.validate_onestop_id_string('s-69y7pwuRetSta')
      expect(is_a_valid_onestop_id).to be false
      expect(errors).to include 'must include 3 components separated by hyphens ("-")'
    end

    it 'must include a valid geohash as its 2nd component, after "s-"' do
      is_a_valid_onestop_id, errors = OnestopId.validate_onestop_id_string('s-69y@7pwu-RetSta')
      expect(is_a_valid_onestop_id).to be false
      expect(errors).to include 'must include a valid geohash as its 2nd component'
    end

    it 'must include only letters, digits, and ~ or @ in its abbreviated name (the 3rd component)' do
      is_a_valid_onestop_id, errors = OnestopId.validate_onestop_id_string('s-9y7pwu-RetSt#a')
      expect(is_a_valid_onestop_id).to be false
      expect(errors).to include 'must include only letters, digits, and ~ or @ in its abbreviated name (the 3rd component)'
      is_a_valid_onestop_id, errors = OnestopId.validate_onestop_id_string('s-9y7pwu-RetSt~a')
      expect(is_a_valid_onestop_id).to be true
      is_a_valid_onestop_id, errors = OnestopId.validate_onestop_id_string('s-9y7pwu-RetSt@a')
      expect(is_a_valid_onestop_id).to be true
    end
  end

  context 'finder methods' do
    before(:each) do
      @glen_park = create(:stop, onestop_id: 's-9q8y-GlenPark', geometry: 'POINT(-122.433416 37.732525)', name: 'Glen Park' )
      @bosworth_diamond = create(:stop, onestop_id: 's-9q8y-BosDiam', geometry: 'POINT(-122.434011 37.733595)', name: 'Bosworth + Diamond')
      @metro_embarcadero = create(:stop, onestop_id: 's-9q8y-MetEmb', geometry: 'POINT(-122.396431 37.793152)', name: 'Metro Embarcadero')
      @gilman_paul_3rd = create(:stop, onestop_id: 's-9q8y-GilPaul3rd', geometry: 'POINT(-122.395644 37.722413)', name: 'Gilman + Paul + 3rd St.')

      @sfmta = create(:operator, onestop_id: 'o-9q8y-SFMTA', geometry: 'POINT(-122.395644 37.722413)', name: 'SFMTA')
    end

    context 'find!' do
      it 'a Stop' do
        found_bosworth_diamond = OnestopId.find!(@bosworth_diamond.onestop_id)
        expect(found_bosworth_diamond.id).to eq @bosworth_diamond.id
      end

      it 'an Operator' do
        found_sfmta = OnestopId.find!(@sfmta.onestop_id)
        expect(found_sfmta.id).to eq @sfmta.id
      end

      it 'will throw an exception when nothing found with that OnestopID' do
        expect {
          OnestopId.find!('s-b3-FakeSt')
        }.to raise_error ActiveRecord::RecordNotFound
      end
    end

    context 'find' do
      it 'returns nil when nothing found with that OnestopID' do
        expect(OnestopId.find('s-b3-FakeSt')).to be_nil
      end
    end
  end
end
