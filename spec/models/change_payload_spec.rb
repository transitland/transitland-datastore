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
  end
end
