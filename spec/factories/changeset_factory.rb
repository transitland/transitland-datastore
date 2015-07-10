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
    notes { FFaker::Lorem.paragraph }
  end

  factory :changeset_with_payload, class: Changeset do
    notes { FFaker::Lorem.paragraph }
    payload {
      {
        changes: [
          {
            action: "createUpdate",
            stop: {
              onestopId: Faker::OnestopId.stop
            }
          }
        ]
      }
    }
  end

end
