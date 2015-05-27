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

class FeedSerializer < ApplicationSerializer
  attributes :onestop_id,
             :url,
             :feed_format,
             :operator_onestop_ids_in_feed,
             :tags,
             :last_sha1,
             :last_fetched_at,
             :last_imported_at,
             :created_at,
             :updated_at,
             :feed_imports_count,
             :feed_imports_url

  def feed_imports_count
    object.feed_imports.count
  end

  def feed_imports_url
    api_v1_feed_feed_imports_url(object.onestop_id)
  end
end
