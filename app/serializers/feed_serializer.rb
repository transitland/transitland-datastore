# == Schema Information
#
# Table name: feeds
#
#  id                              :integer          not null, primary key
#  onestop_id                      :string
#  url                             :string
#  feed_format                     :string
#  tags                            :hstore
#  last_sha1                       :string
#  last_fetched_at                 :datetime
#  last_imported_at                :datetime
#  created_at                      :datetime
#  updated_at                      :datetime
#  license_name                    :string
#  license_url                     :string
#  license_use_without_attribution :string
#  license_create_derived_product  :string
#  license_redistribute            :string
#  operators_in_feed               :hstore           is an Array
#
# Indexes
#
#  index_feeds_on_onestop_id  (onestop_id)
#  index_feeds_on_tags        (tags)
#

class FeedSerializer < ApplicationSerializer
  attributes :onestop_id,
             :url,
             :feed_format,
             :operators_in_feed,
             :tags,
             :license_name,
             :license_url,
             :license_use_without_attribution,
             :license_create_derived_product,
             :license_redistribute,
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
