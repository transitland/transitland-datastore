# == Schema Information
#
# Table name: current_feeds
#
#  id                                 :integer          not null, primary key
#  onestop_id                         :string
#  url                                :string
#  feed_format                        :string
#  tags                               :hstore
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
#  geometry                           :geography({:srid geometry, 4326
#  latest_fetch_exception_log         :text
#
# Indexes
#
#  index_current_feeds_on_created_or_updated_in_changeset_id  (created_or_updated_in_changeset_id)
#

FactoryGirl.define do
  factory :feed do
    url 'http://www.ridemetro.org/News/Downloads/DataFiles/google_transit.zip'
    onestop_id { Faker::OnestopId.feed }
    version 1
  end

  factory :feed_caltrain, class: Feed do
    onestop_id 'f-9q9-caltrain'
    url 'http://www.caltrain.com/Assets/GTFS/caltrain/GTFS-Caltrain-Devs.zip'
    version 1
    after :create do |feed, evaluator|
      operator = create(
        :operator,
        name: 'Caltrain',
        onestop_id: 'o-9q9-caltrain',
        timezone: 'America/Los_Angeles',
        website: 'http://www.caltrain.com',
        version: 1
      )
      feed.operators_in_feed.create(
        operator: operator,
        gtfs_agency_id: 'caltrain-ca-us'
      )
    end
  end

  factory :feed_bart, class: Feed do
    onestop_id 'f-9q9-bart'
    url 'http://www.bart.gov/dev/schedules/google_transit.zip'
    version 1
    after :create do |feed, evaluator|
      operator = create(
        :operator,
        name: 'Bay Area Rapid Transit',
        short_name: 'BART',
        onestop_id: 'o-9q9-bart',
        timezone: 'America/Los_Angeles',
        website: 'http://www.bart.gov',
        version: 1
      )
      feed.operators_in_feed.create(
        operator: operator,
        gtfs_agency_id: 'BART'
      )
    end
  end
end
