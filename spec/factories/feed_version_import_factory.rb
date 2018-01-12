# == Schema Information
#
# Table name: feed_version_imports
#
#  id                :integer          not null, primary key
#  feed_version_id   :integer
#  created_at        :datetime
#  updated_at        :datetime
#  success           :boolean
#  import_log        :text
#  exception_log     :text
#  validation_report :text
#  import_level      :integer
#  operators_in_feed :json
#
# Indexes
#
#  index_feed_version_imports_on_feed_version_id  (feed_version_id)
#

FactoryGirl.define do
  factory :feed_version_import do
    feed_version
  end
end
