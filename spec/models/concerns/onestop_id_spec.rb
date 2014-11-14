describe OnestopId do
  context 'validation' do
    it 'must start with "s-" as its 1st component' do
      stop = Stop.new(onestop_id: '69y7pwu-RetSta', geometry: 'POINT(-58.374722 -34.591389)')
      expect(stop.valid?).to be false
      expect(stop.errors.messages[:onestop_id]).to include 'must start with "s-" as its 1st component'

    end

    it 'must include 3 components separated by hyphens ("-")' do
      stop = Stop.new(onestop_id: 's-69y7pwuRetSta', geometry: 'POINT(-58.374722 -34.591389)')
      expect(stop.valid?).to be false
      expect(stop.errors.messages[:onestop_id]).to include 'must include 3 components separated by hyphens ("-")'
    end

    it 'must include a valid geohash as its 2nd component, after "s-"' do
      stop = Stop.new(onestop_id: 's-69y@7pwu-RetSta', geometry: 'POINT(-58.374722 -34.591389)')
      expect(stop.valid?).to be false
      expect(stop.errors.messages[:onestop_id]).to include 'must include a valid geohash as its 2nd component, after "s-"'
    end

    it 'must include only letters and digits in its abbreviated name (the 3rd component)' do
      stop = Stop.new(onestop_id: '6s-9y7pwu-RetSt#a', geometry: 'POINT(-58.374722 -34.591389)')
      expect(stop.valid?).to be false
      expect(stop.errors.messages[:onestop_id]).to include 'must include only letters and digits in its abbreviated name (the 3rd component)'
    end
  end

  context 'generate_unique_onestop_id' do
    it 'never has spaces or suymbols' do
      stop = Stop.new(name: 'Retiro/Station @Platform #1', geometry: 'POINT(-58.374722 -34.591389)')
      onestop_id = stop.send(:generate_unique_onestop_id)
      expect(onestop_id.split(/[\.\# \@\/\\\+]/).count).to eq 1
    end

    it 'includes a GeoHash as its 2nd (of 3) components, with up to 7 characters of precision' do
      stop = Stop.new(name: 'Retiro Station', geometry: 'POINT(-58.374722 -34.591389)')
      onestop_id = stop.send(:generate_unique_onestop_id)
      expect(onestop_id.split('-').second).to eq '69y7pwu'
    end

    it "when the geometry is a polygon, also includes a GeoHash (of the polygon's centroid)" do
      # TODO: write this
    end

    it 'abbreviates the stop name as the 3rd (of 3) components' do
      stop = Stop.new(name: 'Retiro Station', geometry: 'POINT(-58.374722 -34.591389)')
      onestop_id = stop.send(:generate_unique_onestop_id)
      expect(onestop_id.split('-').last).to eq 'RetSta'
    end
  end
end
