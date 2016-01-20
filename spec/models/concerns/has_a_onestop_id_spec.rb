describe HasAOnestopId do
  context 'validation' do
    it 'for a Stop, must start with "s-" as its 1st component' do
      stop = Stop.new(onestop_id: '9q9-asd')
      expect(stop.valid?).to be false
      expect(stop.errors.messages[:onestop_id]).to include 'invalid name'
    end

    it 'must include name' do
      stop = Stop.new(onestop_id: 's-9q9-')
      expect(stop.valid?).to be false
      expect(stop.errors.messages[:onestop_id]).to include 'invalid name'
    end

    it 'must include geohash' do
      stop = Stop.new(onestop_id: 's--test')
      expect(stop.valid?).to be false
      expect(stop.errors.messages[:onestop_id]).to include 'invalid geohash'
    end

    it 'must include a valid geohash as its 2nd component' do
      stop = Stop.new(onestop_id: 's-aaa-test')
      expect(stop.valid?).to be false
      expect(stop.errors.messages[:onestop_id]).to include 'invalid geohash'
    end

    it 'filters invalid characters' do
      stop = Stop.new(onestop_id: 's-9q9-xyz!')
      expect(stop.valid?).to be false
    end
  end
end
