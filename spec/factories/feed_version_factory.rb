# == Schema Information
#
# Table name: feed_versions
#
#  id                     :integer          not null, primary key
#  feed_id                :integer
#  feed_type              :string
#  file_file_name         :string
#  file_content_type      :string
#  file_file_size         :integer
#  file_updated_at        :datetime
#  earliest_calendar_date :date
#  latest_calendar_date   :date
#  sha1                   :string
#  md5                    :string
#  tags                   :hstore
#  fetched_at             :datetime
#  imported_at            :datetime
#  created_at             :datetime
#  updated_at             :datetime
#
# Indexes
#
#  index_feed_versions_on_feed_type_and_feed_id  (feed_type,feed_id)
#

include ActionDispatch::TestProcess

FactoryGirl.define do
  factory :feed_version do
    feed
    file { fixture_file_upload(Rails.root.join('spec/support/example_gtfs_archives/f-9q9-caltrain.zip'), 'application/zip') }
  end
end
