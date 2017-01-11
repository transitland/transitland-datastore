describe HasAOnestopId do
  context 'find_by_onestop_id!' do
    it 'finds current match' do
      current_stop = create(:stop)
      expect(Stop.find_by_onestop_id!(current_stop.onestop_id)).to eq current_stop
    end

    it 'finds and returns merged match' do
      current_stop = create(:stop)
      old_stop1 = create(:old_stop, current: current_stop, action: 'merge')
      old_stop2 = create(:old_stop, current: current_stop, action: 'merge')
      expect(Stop.find_by_onestop_id!(old_stop1.onestop_id)).to eq current_stop
      expect(Stop.find_by_onestop_id!(old_stop2.onestop_id)).to eq current_stop
    end

    it 'finds and returns changed onestop id match' do
      current_stop = create(:stop)
      old_stop = create(:old_stop, current: current_stop, action: 'change_onestop_id')
      expect(Stop.find_by_onestop_id!(old_stop.onestop_id)).to eq current_stop
    end

    it 'raises error with destroy message if match is destroyed' do
      stop = create(:old_stop)
      expect{ Stop.find_by_onestop_id!(stop.onestop_id) }.to raise_error(ActiveRecord::RecordNotFound, "Stop: #{stop.onestop_id} has been destroyed.")
    end

    it 'raises error if not found' do
      expect{ Stop.find_by_onestop_id!('s-9q9-xyz') }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context 'find_by_onestop_id' do
    it 'finds current match' do
      current_stop = create(:stop)
      expect(Stop.find_by_onestop_id(current_stop.onestop_id)).to eq current_stop
    end

    it 'finds and returns merged match' do
      current_stop = create(:stop)
      old_stop1 = create(:old_stop, current: current_stop, action: 'merge')
      old_stop2 = create(:old_stop, current: current_stop, action: 'merge')
      expect(Stop.find_by_onestop_id(old_stop1.onestop_id)).to eq current_stop
      expect(Stop.find_by_onestop_id(old_stop2.onestop_id)).to eq current_stop
    end

    it 'finds and returns changed onestop id match' do
      current_stop = create(:stop)
      old_stop = create(:old_stop, current: current_stop, action: 'change_onestop_id')
      expect(Stop.find_by_onestop_id(old_stop.onestop_id)).to eq current_stop
    end

    it 'raises error with destroy message if match is destroyed' do
      stop = create(:old_stop)
      expect(Stop.find_by_onestop_id(stop.onestop_id)).to be_nil
    end

    it 'raises error if not found' do
      create(:stop)
      create(:old_stop)
      expect(Stop.find_by_onestop_id('s-9q9-xyz')).to be_nil
    end
  end

  context 'find_by_current_onestop_ids' do
    let(:stop1) { create(:stop) }
    let(:stop2) { create(:stop) }
    it 'returns all matches' do
      expect(Stop.find_by_current_onestop_ids([stop1.onestop_id, stop2.onestop_id])).to match_array([stop1, stop2])
    end

    it 'filters out missing' do
      expect(Stop.find_by_current_onestop_ids([stop1.onestop_id, 's-9q9-missing'])).to match_array([stop1])
    end
  end

  context 'find_by_current_onestop_ids!' do
    let(:stop1) { create(:stop) }
    let(:stop2) { create(:stop) }
    it 'returns all matches' do
      expect(Stop.find_by_current_onestop_ids!([stop1.onestop_id, stop2.onestop_id])).to match_array([stop1, stop2])
    end

    it 'raises exception on missing' do
      expect { Stop.find_by_current_onestop_ids!(['s-9q9-missing']) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

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
