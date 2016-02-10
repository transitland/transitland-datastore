# Create a concrete class for testing
class TestOnestopId < OnestopId::OnestopIdBase
  PREFIX = :s
  MODEL = Stop
  NUM_COMPONENTS = 3
end

class TestRSPOnestopId < OnestopId::RouteStopPatternOnestopId
  PREFIX = :r
  MODEL = RouteStopPattern
  NUM_COMPONENTS = 5
  HASH_LENGTH = 6
end

describe OnestopId do
  it 'fails gracefully when given an invalid geometry' do
    expect {
      TestOnestopId.new('Retiro Station', '-58.374722 -34.591389')
    }.to raise_error(ArgumentError)

    expect {
      TestOnestopId.new('Retiro Station', [-58.374722,-34.591389])
    }.to raise_error(ArgumentError)
    expect {
      TestOnestopId.new(name: 'Retiro Station')
    }.to raise_error(ArgumentError)
    expect {
      TestOnestopId.new(geohash: '9q9')
    }.to raise_error(ArgumentError)
  end

  context '#geohash' do
    it 'filters geohashes' do
      expect(
        TestOnestopId.new(geohash: 'a9q9', name: 'test').to_s
      ).to eq('s-9q9-test')
    end
  end

  context '#name' do
    it 'allows only letters, digits, ~, @ in name' do
      expect(TestOnestopId.new(geohash: '9q9', name: 'foo bar').to_s).to eq('s-9q9-foobar')
      expect(TestOnestopId.new(geohash: '9q9', name: 'foo bar!').to_s).to eq('s-9q9-foobar')
      expect(TestOnestopId.new(geohash: '9q9', name: 'foo~bar').to_s).to eq('s-9q9-foo~bar')
      expect(TestOnestopId.new(geohash: '9q9', name: 'foo~bar0').to_s).to eq('s-9q9-foo~bar0')
    end
  end

  context '#validate' do
    it 'requires valid geohash' do
      expect(TestOnestopId.new(geohash: 'a@', name: 'test').errors).to include 'invalid geohash'
    end
    it 'requires name' do
      expect(TestOnestopId.new(geohash: '9q9', name: '!').errors).to include 'invalid name'
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
