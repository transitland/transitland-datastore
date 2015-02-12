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

FactoryGirl.define do
  factory :changeset do
    notes { Faker::Lorem.paragraph }
    payload {
      {
        changes: [
          {
            action: "createUpdate",
            stop: {
              onestopId: 's-9q8yt4b-1AvHoS'
            }
          }
        ]
      }
    }
  end
end
