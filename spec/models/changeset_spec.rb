# == Schema Information
#
# Table name: changesets
#
#  id         :integer          not null, primary key
#  notes      :text
#  applied    :boolean
#  applied_at :datetime
#  created_at :datetime
#  updated_at :datetime
#

describe Changeset do
  it 'can be created' do
    changeset = create(:changeset)
    expect(Changeset.exists?(changeset.id)).to be true
  end

  it 'can append a payload' do
    changeset = build(:changeset)
    payload = {
      changes: [
        {
          action: "createUpdate",
          stop: {
            onestopId: 's-9q8yt4b-1AvHoS',
            name: '1st Ave. & Holloway St.'
          }
        }
      ]
    }
    expect(changeset.change_payloads.count).equal?(0)
    changeset.append(payload)
    expect(changeset.change_payloads.count).equal?(1)
  end

  context 'can be applied' do
    before(:each) do
      @changeset1 = create(:changeset, payload: {
        changes: [
          {
            action: 'createUpdate',
            stop: {
              onestopId: 's-9q8yt4b-1AvHoS',
              name: '1st Ave. & Holloway Street'
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
              name: '1st Ave. & Holloway St.'
            }
          }
        ]
      })
      @changeset2_bad = create(:changeset, payload: {
        changes: [
          {
            action: 'destroy',
            stop: {
              onestopId: 's-9q8yt4b-1Av',
            }
          }
        ]
      })
      @changeset3 = create(:changeset, payload: {
        changes: [
          {
            action: 'destroy',
            stop: {
              onestopId: 's-9q8yt4b-1AvHoS'
            }
          }
        ]
      })
    end

    it 'trial_succeeds?' do
      @changeset1.apply!
      expect(Stop.find_by_onestop_id!('s-9q8yt4b-1AvHoS').name).to eq '1st Ave. & Holloway Street'
      expect(@changeset2.applied).to eq false
      expect(@changeset2.trial_succeeds?).to eq true
      expect(@changeset2.reload.applied).to eq false
      expect(Stop.find_by_onestop_id!('s-9q8yt4b-1AvHoS').name).to eq '1st Ave. & Holloway Street'
      expect(@changeset2_bad.trial_succeeds?).to eq false
      @changeset2.apply!
      expect(Stop.find_by_onestop_id!('s-9q8yt4b-1AvHoS').name).to eq '1st Ave. & Holloway St.'
    end

    it 'and will set applied and applied_at values' do
      expect(@changeset1.applied).to eq false
      expect(@changeset1.applied_at).to be_blank
      @changeset1.apply!
      expect(@changeset1.applied).to eq true
      expect(@changeset1.applied_at).to be_within(1.minute).of(Time.now)
    end

    it 'once but not twice' do
      @changeset1.apply!
      expect(Stop.find_by_onestop_id!('s-9q8yt4b-1AvHoS').name).to eq '1st Ave. & Holloway Street'
      expect {
        @changeset1.apply!
      }.to raise_error(Changeset::Error)
    end

    it 'to update an existing entity' do
      @changeset1.apply!
      expect(Stop.find_by_onestop_id!('s-9q8yt4b-1AvHoS').name).to eq '1st Ave. & Holloway Street'
      @changeset2.apply!
      expect(Stop.find_by_onestop_id!('s-9q8yt4b-1AvHoS').name).to eq '1st Ave. & Holloway St.'
    end

    it 'to delete an existing entity' do
      @changeset1.apply!
      expect(Stop.count).to eq 1
      @changeset2.apply!
      expect(Stop.count).to eq 1
      expect(OldStop.count).to eq 1
      @changeset3.apply!
      expect(Stop.count).to eq 0
      expect(OldStop.count).to eq 2
      expect(Stop.find_by_onestop_id('s-9q8yt4b-1AvHoS')).to be_nil
    end
    
    it 'deletes payloads after applying' do
      payload_ids = @changeset1.change_payload_ids
      expect(payload_ids.length).to eq 1
      @changeset1.apply!
      payload_ids.each do |i|
        expect(ChangePayload.find_by(id: i)).to be_nil
      end
    end

    it 'to create and remove a relationship' do
      @changeset1.apply!
      @changeset2.apply!
      changeset3 = create(:changeset, payload: {
        changes: [
          {
            action: 'createUpdate',
            operator: {
              onestopId: 'o-9q8y-SFMTA',
              name: 'SFMTA',
              serves: ['s-9q8yt4b-1AvHoS']
            },
          }
        ]
      })
      expect(Stop.find_by_onestop_id!('s-9q8yt4b-1AvHoS').operators.count).to eq 0
      changeset3.apply!
      expect(Stop.find_by_onestop_id!('s-9q8yt4b-1AvHoS').operators).to include Operator.find_by_onestop_id!('o-9q8y-SFMTA')

      changeset4 = create(:changeset, payload: {
        changes: [
          {
            action: 'createUpdate',
            stop: {
              onestopId: 's-9q8yt4b-1AvHoS',
              notServedBy: ['o-9q8y-SFMTA']
            },
          }
        ]
      })
      changeset4.apply!
      expect(Stop.find_by_onestop_id!('s-9q8yt4b-1AvHoS').operators.count).to eq 0
      expect(OldOperatorServingStop.count).to eq 1
      expect(OldOperatorServingStop.first.operator).to eq Operator.find_by_onestop_id!('o-9q8y-SFMTA')
      expect(OldOperatorServingStop.first.stop).to eq Stop.find_by_onestop_id!('s-9q8yt4b-1AvHoS')
    end
  end

  context 'revert' do
    pending 'write some specs'
  end

  it 'will conflate stops with OSM after the DB transaction is complete' do
    allow(Figaro.env).to receive(:auto_conflate_stops_with_osm) { 'true' }
    changeset = create(:changeset, payload: {
      changes: [
        {
          action: 'createUpdate',
          stop: {
            onestopId: 's-9q8yt4b-1AvHoS',
            name: '1st Ave. & Holloway Street',
          }
        }
      ]
    })
    allow(ConflateStopsWithOsmWorker).to receive(:perform_async) { true }
    # WARNING: we're expecting certain a ID in the database. This might
    # not be the case if the test suite is run in parallel.
    expect(ConflateStopsWithOsmWorker).to receive(:perform_async).with([1])
    changeset.apply!
  end
end
