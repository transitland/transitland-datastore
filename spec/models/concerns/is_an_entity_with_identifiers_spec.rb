describe IsAnEntityWithIdentifiers do
  context 'changesets' do
    before(:each) do
      @changeset1 = create(:changeset, payload: {
        changes: [
          {
            action: 'createUpdate',
            stop: {
              onestopId: 's-9q8yt4b-1AvHoS',
              name: '1st Ave. & Holloway Street',
              identifiedBy: ['gtfs://sfmta/53532']
            }
          }
        ]
      })
      @changeset2 = create(:changeset, payload: {
        changes: [
          {
            action: 'createUpdate',
            stop: {
              onestopId: 's-9q8yt4b-1AvHoS',
              name: '1st Ave. & Holloway St.',
              identifiedBy: ['gtfs://sfmta/53531'],
              notIdentifiedBy: ['SPURIOUS-ID-THAT-NEVER-EXISTED']
            }
          }
        ]
      })
      @changeset3 = create(:changeset, payload: {
        changes: [
          {
            action: 'createUpdate',
            stop: {
              onestopId: 's-9q8yt4b-1AvHoS',
              name: '1st Ave. & Holloway St.',
              notIdentifiedBy: ['gtfs://sfmta/53532', 'SPURIOUS-ID-THAT-NEVER-EXISTED']
            }
          }
        ]
      })
    end

    it 'can set identifiers' do
      @changeset1.apply!
      expect(Stop.find_by_onestop_id!('s-9q8yt4b-1AvHoS').identifiers).to match_array ['gtfs://sfmta/53532']
    end

    it 'can add identifiers' do
      @changeset1.apply!
      @changeset2.apply!
      expect(Stop.find_by_onestop_id!('s-9q8yt4b-1AvHoS').identifiers).to match_array ['gtfs://sfmta/53532', 'gtfs://sfmta/53531']
    end

    it 'can remove identifiers' do
      @changeset1.apply!
      @changeset2.apply!
      @changeset3.apply!
      expect(Stop.find_by_onestop_id!('s-9q8yt4b-1AvHoS').identifiers).to match_array ['gtfs://sfmta/53531']
    end
  end
end
