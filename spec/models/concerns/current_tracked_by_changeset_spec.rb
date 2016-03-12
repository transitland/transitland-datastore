describe CurrentTrackedByChangeset do
  let(:stop) { create(:stop) }

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
