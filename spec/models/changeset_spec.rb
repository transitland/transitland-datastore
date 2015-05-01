# == Schema Information
#
# Table name: changesets
#
#  id         :integer          not null, primary key
#  notes      :text
#  applied    :boolean
#  applied_at :datetime
#  payload    :json
#  created_at :datetime
#  updated_at :datetime
#

describe Changeset do
  it 'can be created' do
    changeset = create(:changeset)
    expect(Changeset.exists?(changeset.id)).to be true
  end

  context 'payload' do
    it 'must contain at least one change' do
      changeset = build(:changeset, payload: { changes: [] })
      expect(changeset.valid?).to be false
      expect(changeset.errors.messages[:payload][0]).to include "The property '#/changes' did not contain a minimum number of items 1"
    end

    it 'can contain a stop creation/update' do
      changeset = build(:changeset, payload: {
        changes: [
          {
            action: "createUpdate",
            stop: {
              onestopId: 's-9q8yt4b-1AvHoS',
              name: '1st Ave. & Holloway St.'
            }
          }
        ]
      })
      expect(changeset.valid?).to be true
    end

    it 'must include valid Onestop IDs' do
      changeset = build(:changeset, payload: {
        changes: [
          {
            action: "destroy",
            operator: {
              onestopId: '9q8yt4b-1AvHoS'
            }
          }
        ]
      })
      expect(changeset.valid?).to be false
    end

    it 'can contain a stop destruction' do
      changeset = build(:changeset, payload: {
        changes: [
          {
            action: "destroy",
            stop: {
              onestopId: 's-9q8yt4b-1AvHoS'
            }
          }
        ]
      })
      expect(changeset.valid?).to be true
    end
  end

  context 'can be applied' do
    before(:each) do
      @changeset1 = create(:changeset, payload: {
        changes: [
          {
            action: 'createUpdate',
            stop: {
              onestopId: 's-9q8yt4b-1AvHoS',
              name: '1st Ave. & Holloway Street',
              identifiers: ['gtfs://sfmta/53532']
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
end
