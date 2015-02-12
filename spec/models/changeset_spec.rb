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

RSpec.describe Changeset, :type => :model do
  it 'can be created' do
    changeset = create(:changeset)
    expect(Changeset.exists?(changeset.id)).to be true
  end

  context 'payload' do
    it 'must contain at least one change' do
      changeset = build(:changeset, payload: { changes: [] })
      expect(changeset.valid?).to be false
      expect(changeset.errors.messages[:payload][0][0]).to include "The property '#/changes' did not contain a minimum number of items 1"
    end

    it 'can contain a stop creation/update' do
      changeset = build(:changeset, payload: {
        changes: [
          {
            action: "createUpdate",
            stop: {
              onestopId: 's-9q8yt4b-1AvHoS',
              name: '1st Ave. & Holloway St.',
              operatorsServingStop: [
                {
                  operatorOnestopId: "o-9q8y-SFMTA"
                }
              ]
            }
          }
        ]
      })
      expect(changeset.valid?).to be true
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
              operatorsServingStop: [
                {
                  operatorOnestopId: 'o-9q8y-SFMTA'
                }
              ]
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
            }
          }
        ]
      })
      @changeset2_bad = create(:changeset, payload: {
        changes: [
          {
            action: 'createUpdate',
            stop: {
              onestopId: 's-9q8yt4b',
              name: '1st Ave. & Holloway St.',
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

    it 'as a check in advance (and then rolled back)' do
      @changeset1.apply!
      expect(Stop.find_by_onestop_id!('s-9q8yt4b-1AvHoS').name).to eq '1st Ave. & Holloway Street'
      expect(@changeset2.is_valid_and_can_be_cleanly_applied?). to eq true
      expect(@changeset2_bad.is_valid_and_can_be_cleanly_applied?). to eq false
      expect(Stop.find_by_onestop_id!('s-9q8yt4b-1AvHoS').name).to eq '1st Ave. & Holloway Street'
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
      expect(Stop.count).to eq 2
      expect(Stop.current.count).to eq 1
      @changeset3.apply!
      expect(Stop.count).to eq 2
      expect(Stop.current.count).to eq 0
      expect(Stop.find_by_onestop_id('s-9q8yt4b-1AvHoS')).to be_nil
    end
  end

  context 'revert' do
    pending 'write some specs'
  end
end
