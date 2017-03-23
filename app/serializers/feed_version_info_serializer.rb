# == Schema Information
#
# Table name: feed_version_infos
#
#  id              :integer          not null, primary key
#  type            :string
#  data            :json
#  feed_version_id :integer
#  created_at      :datetime
#  updated_at      :datetime
#
# Indexes
#
#  index_feed_version_infos_on_feed_version_id  (feed_version_id)
#

class FeedVersionInfoSerializer < ApplicationSerializer
  attributes :id,
             :data,
             :feed_version_sha1,
             :created_at,
             :updated_at

  # def feed_onestop_id
  #   object.feed.onestop_id
  # end

  def feed_version_sha1
    object.feed_version.sha1
  end
end
