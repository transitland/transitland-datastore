describe CurrentTrackedByChangeset do
  let(:stop) { create(:stop) }

  context '#merge' do
    it 'merges changeable attributes' do
      stop1 = create(:stop)
      stop2 = create(:stop, name: 'Test')
      stop1.merge(stop2)
      expect(stop1.name).to eq(stop2.name)
    end

    it 'does not merge non-changeable attributes' do
      stop1 = create(:stop, version: 1)
      stop2 = create(:stop, version: 2)
      stop1.merge(stop2)
      expect(stop1.version).to eq(1)
      expect(stop2.version).to eq(2)
    end

    it 'merges tags' do
      stop1 = create(:stop)
      stop2 = create(:stop)
      stop1.tags = {}
      stop1.tags[:test] = '123'
      stop2.tags = {}
      stop2.tags[:foo] = 'bar'
      stop1.merge(stop2)
      expect(stop1.tags).to eq({"test"=>"123", "foo"=>"bar"})
    end

    it 'does not merge protected attributes' do
      stop1 = create(:stop)
      stop2 = create(:stop)
      stop1.identifiers = ['foo']
      stop2.identifiers = ['bar']
      stop1.merge(stop2)
      expect(stop1.identifiers).to match_array(['foo'])
    end

    it 'converts empty string to nil' do
      route1 = create(:route, color: 'FFFFFF')
      route2 = create(:route, color: '')
      route1.merge(route2)
      expect(route1.color).to eq(nil)
    end
  end

  context "#as_change" do
    it "converts to camelCase" do
      expect(stop.as_change[:onestopId]).to eq(stop.onestop_id)
    end

    it "only includes changeable attributes" do
      expect(stop.as_change[:createdAt]).to be nil
      expect(stop.as_change[:updatedAt]).to be nil
    end

    it "includes virtual attributes" do
      expect(stop.as_change.include?(:servedBy)).to be true
    end

    it "does not include foreign keys" do
      expect(stop.as_change[:created_or_updated_in_changeset]).to be nil
    end

    it "filters out edited attributes" do
      
    end
  end
end
