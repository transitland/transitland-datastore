# == Schema Information
#
# Table name: feed_schedule_imports
#
#  id                     :integer          not null, primary key
#  success                :boolean
#  import_log             :text
#  exception_log          :text
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  feed_version_import_id :integer
#
# Indexes
#
#  index_feed_schedule_imports_on_feed_version_import_id  (feed_version_import_id)
#

FactoryGirl.define do
  factory :feed_schedule_import do
    feed_version_import
  end
end
