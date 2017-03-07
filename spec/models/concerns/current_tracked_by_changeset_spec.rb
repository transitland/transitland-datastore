describe CurrentTrackedByChangeset do
  let(:stop) { create(:stop) }

  context '#merge' do
    it 'merges changeable attributes' do
      stop1 = create(:stop)
      stop2 = create(:stop, name: 'Test')
      stop1.merge_in_entity(stop2)
      expect(stop1.name).to eq(stop2.name)
    end

    it 'does not merge non-changeable attributes' do
      stop1 = create(:stop, version: 1)
      stop2 = create(:stop, version: 2)
      stop1.merge_in_entity(stop2)
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
      stop1.merge_in_entity(stop2)
      expect(stop1.tags).to eq({"test"=>"123", "foo"=>"bar"})
    end

    it 'does not merge protected attributes' do
      stop1 = create(:stop)
      stop2 = create(:stop)
      now = Datetime.now
      stop1.last_conflated_at = now - 1.day
      stop2.last_conflated_at = now - 2.days
      stop1.merge_in_entity(stop2)
      expect(stop1.last_conflated_at).to eq(now - 1.day)
    end

    it 'converts empty string to nil' do
      route1 = create(:route, color: 'FFFFFF')
      route2 = create(:route, color: '')
      route1.merge_in_entity(route2)
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
      stop.wheelchair_boarding = true
      stop.edited_attributes << :wheelchair_boarding
      expect(stop.as_change(sticky: true)[:wheelchairBoarding]).to be nil
    end
  end

  it 'updates edited_attributes during create and update' do
    stop.wheelchair_boarding = true
    changeset = create(:changeset)
    changeset.create_change_payloads([stop])
    Stop.apply_change(action: 'createUpdate', changeset: changeset, change: changeset.change_payloads.first.payload_as_ruby_hash[:changes][0][:stop])
    expect(Stop.find_by_onestop_id!(stop.onestop_id).edited_attributes).to include("wheelchair_boarding")
  end
end
