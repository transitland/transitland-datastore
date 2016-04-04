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
      stop2 = create(:stop, version: 2, name: 'Test')
      stop1.merge(stop2)
      expect(stop1.version).to eq(1)
      expect(stop2.version).to eq(2)
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
  end
end
