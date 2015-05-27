# == Schema Information
#
# Table name: feeds
#
#  id                           :integer          not null, primary key
#  onestop_id                   :string
#  url                          :string
#  feed_format                  :string
#  tags                         :hstore
#  operator_onestop_ids_in_feed :string           default([]), is an Array
#  last_sha1                    :string
#  last_fetched_at              :datetime
#  last_imported_at             :datetime
#  created_at                   :datetime
#  updated_at                   :datetime
#
# Indexes
#
#  index_feeds_on_onestop_id  (onestop_id)
#

FactoryGirl.define do
  factory :feed do
    url { 'http://www.ridemetro.org/News/Downloads/DataFiles/google_transit.zip' }
    onestop_id { Faker::OnestopId.feed }
  end
end
