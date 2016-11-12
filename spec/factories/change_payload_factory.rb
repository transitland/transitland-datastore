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

FactoryGirl.define do
  factory :change_payload do
    payload {
      {
        changes: [
          {
            action: "createUpdate",
            stop: {
              onestopId: Faker::OnestopId.stop,
              timezone: 'America/Los_Angeles',
              geometry: { type: 'Point', coordinates: [10.195312, 43.755225] }
            }
          }
        ]
      }
    }
  end
end
