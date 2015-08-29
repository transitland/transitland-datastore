# == Schema Information
#
# Table name: feeds
#
#  id                              :integer          not null, primary key
#  onestop_id                      :string
#  url                             :string
#  feed_format                     :string
#  tags                            :hstore
#  last_sha1                       :string
#  last_fetched_at                 :datetime
#  last_imported_at                :datetime
#  created_at                      :datetime
#  updated_at                      :datetime
#  license_name                    :string
#  license_url                     :string
#  license_use_without_attribution :string
#  license_create_derived_product  :string
#  license_redistribute            :string
#  operators_in_feed               :hstore           is an Array
#
# Indexes
#
#  index_feeds_on_onestop_id  (onestop_id)
#  index_feeds_on_tags        (tags)
#

FactoryGirl.define do
  factory :feed do
    url { 'http://www.ridemetro.org/News/Downloads/DataFiles/google_transit.zip' }
    onestop_id { Faker::OnestopId.feed }
  end
end
