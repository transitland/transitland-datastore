# == Schema Information
#
# Table name: feed_version_infos
#
#  id                :integer          not null, primary key
#  statistics        :json
#  scheduled_service :json
#  filenames         :string           is an Array
#  created_at        :datetime
#  updated_at        :datetime
#

class FeedVersionInfoSerializer < ApplicationSerializer
  attributes :id,
             :statistics,
             :scheduled_service,
             :filenames,
             :feed_onestop_id,
             :feed_version_sha1,
             :created_at,
             :updated_at

  def feed_onestop_id
    object.feed.onestop_id
  end

  def feed_version_sha1
    object.feed_version.sha1
  end
end
