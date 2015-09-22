# == Schema Information
#
# Table name: current_feeds
#
#  id                                 :integer          not null, primary key
#  onestop_id                         :string
#  url                                :string
#  feed_format                        :string
#  tags                               :hstore
#  last_sha1                          :string
#  last_fetched_at                    :datetime
#  last_imported_at                   :datetime
#  license_name                       :string
#  license_url                        :string
#  license_use_without_attribution    :string
#  license_create_derived_product     :string
#  license_redistribute               :string
#  version                            :integer
#  created_at                         :datetime
#  updated_at                         :datetime
#  created_or_updated_in_changeset_id :integer
#
# Indexes
#
#  index_current_feeds_on_created_or_updated_in_changeset_id  (created_or_updated_in_changeset_id)
#

FactoryGirl.define do
  factory :feed do
    url { 'http://www.ridemetro.org/News/Downloads/DataFiles/google_transit.zip' }
    onestop_id { Faker::OnestopId.feed }
  end

  factory :feed_caltrain, class: Feed do
    onestop_id { 'f-9q9-caltrain' }
    url { 'http://www.caltrain.com/Assets/GTFS/caltrain/GTFS-Caltrain-Devs.zip' }
    operators_in_feed [
      {
        onestop_id: "o-9q9-caltrain",
        gtfs_agency_id: "caltrain-ca-us"
      }
    ]
  end

end
