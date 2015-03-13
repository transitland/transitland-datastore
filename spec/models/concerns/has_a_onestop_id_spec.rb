describe HasAOnestopId do
  context 'validation' do
    it 'for a Stop, must start with "s-" as its 1st component' do
      stop = Stop.new(onestop_id: '69y7pwu-RetSta', geometry: 'POINT(-58.374722 -34.591389)')
      expect(stop.valid?).to be false
      expect(stop.errors.messages[:onestop_id]).to include 'must start with "s" as its 1st component'

    end

    it 'must include 3 components separated by hyphens ("-")' do
      stop = Stop.new(onestop_id: 's-69y7pwuRetSta', geometry: 'POINT(-58.374722 -34.591389)')
      expect(stop.valid?).to be false
      expect(stop.errors.messages[:onestop_id]).to include 'must include 3 components separated by hyphens ("-")'
    end

    it 'must include a valid geohash as its 2nd component' do
      stop = Stop.new(onestop_id: 's-69y@7pwu-RetSta', geometry: 'POINT(-58.374722 -34.591389)')
      expect(stop.valid?).to be false
      expect(stop.errors.messages[:onestop_id]).to include 'must include a valid geohash as its 2nd component'
    end

    it 'must include only letters and digits in its abbreviated name (the 3rd component)' do
      stop = Stop.new(onestop_id: '6s-9y7pwu-RetSt#a', geometry: 'POINT(-58.374722 -34.591389)')
      expect(stop.valid?).to be false
      expect(stop.errors.messages[:onestop_id]).to include 'must include only letters, digits, and ~ or @ in its abbreviated name (the 3rd component)'
    end
  end
end
