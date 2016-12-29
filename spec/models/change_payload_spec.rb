# == Schema Information
#
# Table name: change_payloads
#
#  id           :integer          not null, primary key
#  payload      :json
#  changeset_id :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_change_payloads_on_changeset_id  (changeset_id)
#

RSpec.describe ChangePayload, type: :model do
  # Changeset/ChangePayload tests are in changeset_spec.rb

  it 'can be created' do
    change_payload = create(:change_payload)
    expect(ChangePayload.exists?(change_payload.id)).to be true
  end

  context 'payload' do
    it 'may not contain empty changes' do
      change_payload = build(:change_payload, payload: { changes: [] })
      expect(change_payload.valid?).to be false
    end

    it 'can contain a stop creation/update' do
      change_payload = build(:change_payload, payload: {
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
      expect(change_payload.valid?).to be true
    end

    it 'must include valid Onestop IDs' do
      change_payload = build(:change_payload, payload: {
        changes: [
          {
            action: "destroy",
            operator: {
              onestopId: 'invalid-onestop-id'
            }
          }
        ]
      })
      expect(change_payload.valid?).to be false
    end

    it 'must include a schema valid payload' do
      change_payload = build(:change_payload, payload: {
        changes: [
          {
            asd: "xyz"
          }
        ]
      })
      expect(change_payload.valid?).to be false
    end

    it 'can contain a stop destruction' do
      change_payload = build(:change_payload, payload: {
        changes: [
          {
            action: "destroy",
            stop: {
              onestopId: 's-9q8yt4b-1AvHoS'
            }
          }
        ]
      })
      expect(change_payload.valid?).to be true
    end

    it 'updates edited_attributes during create and update' do
      stop = create(:stop)
      stop.wheelchair_boarding = true
      change_payload = build(:change_payload, payload: {
        changes: [
          {
            action: "createUpdate",
            stop: stop.as_change
          }
        ]
      })
      change_payload.changeset = create(:changeset)
      change_payload.apply!
      expect(Stop.find_by_onestop_id!(stop.onestop_id).edited_attributes).to include("wheelchair_boarding")
    end

    it 'apply! returns set of issues to deprecate' do
      stop = create(:stop, onestop_id: 's-9q8yt4b-1AvHoS', name: '1st Ave. & Holloway St.')
      issue = Issue.create!(issue_type: 'other', details: 'there\'s nothing wrong.')
      issue.entities_with_issues.create!(entity: stop, entity_attribute: 'name')
      change_payload = build(:change_payload, payload: {
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
      expect(change_payload.apply!).to match_array([[], Set.new([issue])])
    end
  end
end
