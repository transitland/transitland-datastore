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

class FeedVersionSerializer < ApplicationSerializer
  attributes :sha1,
             :earliest_calendar_date,
             :latest_calendar_date,
             :md5,
             :tags,
             :fetched_at,
             :imported_at,
             :created_at,
             :updated_at,
             :feed_version_imports,
             :feed_version_imports_url

  def feed_version_imports
    object.feed_version_imports.pluck(:id)
  end

  def feed_version_imports_url
    api_v1_feed_feed_version_feed_version_imports_url(object.feed.onestop_id, object.sha1)
  end

end
