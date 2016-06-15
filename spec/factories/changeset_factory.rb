# == Schema Information
#
# Table name: changesets
#
#  id              :integer          not null, primary key
#  notes           :text
#  applied         :boolean
#  applied_at      :datetime
#  created_at      :datetime
#  updated_at      :datetime
#  user_id         :integer
#  feed_id         :integer
#  feed_version_id :integer
#
# Indexes
#
#  index_changesets_on_feed_id          (feed_id)
#  index_changesets_on_feed_version_id  (feed_version_id)
#  index_changesets_on_user_id          (user_id)
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
              onestopId: Faker::OnestopId.stop,
              timezone: 'America/Los_Angeles'
            }
          }
        ]
      }
    }
  end

  factory :changeset_creating_issue, class: Changeset do
    notes { FFaker::Lorem.paragraph }
    payload {
      {
        changes: [
          {
            action: "createUpdate",
            stop: {
              onestopId: Faker::OnestopId.stop,
              timezone: 'America/Los_Angeles',
              geometry: {
                type: "Point",
                coordinates: [-75.1, 43.8]
              }
            },
            routeStopPattern: {
              onestopId: Faker::OnestopId.route_stop_pattern,
              geometry: {
                type: "Linestring",
                coordinates: [[-122.353165, 37.936887],[-122.38666, 37.599787]]
              }
            }
          }
        ]
      }
    }
  end
end
