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

  context 'scopes' do
    it 'with_identifier' do
      # TODO
    end

    it 'with_identifier_or_name' do
      # TODO
    end

    it 'with_identifier_starting_with' do
      sfmta1 = create(:stop, geometry: 'POINT(-122.38588 37.7366)', name: 'Cashmere St & Whitney Young Cir', identifiers: ['gtfs://f-9q8y-sanfranciscomunicipaltransportationagency/s/3922'])
      sfmta2 = create(:stop, geometry: 'POINT(-122.405021 37.708997)', name: 'Bay Shore Blvd & Sunnydale Ave', identifiers: ['gtfs://f-9q8y-sanfranciscomunicipaltransportationagency/s/7398'])
      bart = create(:stop, geometry: 'POINT(-122.353165 37.936887)', name: 'Richmond', identifiers: ['gtfs://f-9q9-bayarearapidtransit/s/RICH'])

      expect(Stop.with_identifer_starting_with('gtfs://f-9q8y-sanfranciscomunicipaltransportationagency/s/')).to match_array([sfmta1, sfmta2])
      expect(Stop.with_identifer_starting_with('gtfs://')).to match_array([sfmta1, sfmta2, bart])
    end
  end
end
