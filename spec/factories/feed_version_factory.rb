# == Schema Information
#
# Table name: feed_versions
#
#  id                     :integer          not null, primary key
#  feed_id                :integer
#  feed_type              :string
#  file                   :string
#  earliest_calendar_date :date
#  latest_calendar_date   :date
#  sha1                   :string
#  md5                    :string
#  tags                   :hstore
#  fetched_at             :datetime
#  imported_at            :datetime
#  created_at             :datetime
#  updated_at             :datetime
#  import_level           :integer          default(0)
#
# Indexes
#
#  index_feed_versions_on_feed_type_and_feed_id  (feed_type,feed_id)
#

FactoryGirl.define do
  factory :feed_version do
  sha1 { SecureRandom.hex(32) }
  feed
    factory :feed_version_caltrain do
      file { File.open(Rails.root.join('spec/support/example_gtfs_archives/f-9q9-caltrain.zip')) }
      association :feed, factory: :feed_caltrain
    end

    factory :feed_version_bart do
      file { File.open(Rails.root.join('spec/support/example_gtfs_archives/f-9q9-bart.zip')) }
      association :feed, factory: :feed_bart
    end

    factory :feed_version_vta do
      file { File.open(Rails.root.join('spec/support/example_gtfs_archives/vta-trip-1930705-gtfs.zip')) }
      association :feed, factory: :feed_vta
    end

    factory :feed_version_example do
      file { File.open(Rails.root.join('spec/support/example_gtfs_archives/example.zip')) }
      association :feed, factory: :feed_example
    end
  end
end
