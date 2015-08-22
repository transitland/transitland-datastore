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
#
# Indexes
#
#  index_feed_version_imports_on_feed_version_id  (feed_version_id)
#

class FeedVersionImportSerializer < ApplicationSerializer
  attributes :feed_onestop_id,
             :feed_url,
             :success,
             :sha1,
             :import_log,
             :exception_log,
             :validation_report,
             :created_at,
             :updated_at

  has_many :feed_schedule_imports

  def feed_onestop_id
    object.feed.onestop_id
  end

  def feed_url
    api_v1_feed_url(object.feed.onestop_id)
  end
end
