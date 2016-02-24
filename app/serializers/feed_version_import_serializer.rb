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
  attributes :id,
             :feed,
             :feed_version,
             :feed_url,
             :feed_version_url,
             :success,
             :import_log,
             :exception_log,
             :validation_report,
             :created_at,
             :updated_at,
             :imported_from_changesets

  has_many :feed_schedule_imports

  def feed
    object.feed.onestop_id
  end

  def feed_version
    object.feed_version.sha1
  end

  def feed_url
    api_v1_feed_url(object.feed.onestop_id)
  end

  def feed_version_url
    api_v1_feed_version_url(object.feed_version.sha1)
  end

  def imported_from_changesets
    object.imported_from_changesets.map(&:id)
  end
end
