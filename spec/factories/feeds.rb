# == Schema Information
#
# Table name: feeds
#
#  id               :integer          not null, primary key
#  url              :string(255)
#  feed_format      :string(255)
#  last_fetched_at  :datetime
#  last_imported_at :datetime
#  created_at       :datetime
#  updated_at       :datetime
#

FactoryGirl.define do
  factory :feed do
    url 'http://gtfs.s3.amazonaws.com/santa-cruz-metro_20140607_0125.zip'
    feed_format :gtfs
  end
end
