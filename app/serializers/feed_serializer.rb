# == Schema Information
#
# Table name: current_feeds
#
#  id                                 :integer          not null, primary key
#  onestop_id                         :string
#  url                                :string
#  feed_format                        :string
#  tags                               :hstore
#  last_fetched_at                    :datetime
#  last_imported_at                   :datetime
#  license_name                       :string
#  license_url                        :string
#  license_use_without_attribution    :string
#  license_create_derived_product     :string
#  license_redistribute               :string
#  version                            :integer
#  created_at                         :datetime
#  updated_at                         :datetime
#  created_or_updated_in_changeset_id :integer
#  geometry                           :geography({:srid geometry, 4326
#
# Indexes
#
#  index_current_feeds_on_created_or_updated_in_changeset_id  (created_or_updated_in_changeset_id)
#

class FeedSerializer < ApplicationSerializer
  attributes :onestop_id,
             :url,
             :feed_format,
             :tags,
             :geometry,
             :license_name,
             :license_url,
             :license_use_without_attribution,
             :license_create_derived_product,
             :license_redistribute,
             :last_fetched_at,
             :last_imported_at,
             :import_status,
             :created_at,
             :updated_at,
             :feed_versions_count,
             :feed_versions_url,
             :feed_versions

  has_many :operators_in_feed

  def feed_versions_count
    object.feed_versions.count
  end

  def feed_versions_url
    api_v1_feed_feed_versions_url(object.onestop_id)
  end

  def feed_versions
    object.feed_versions.pluck(:sha1)
  end
end
