# == Schema Information
#
# Table name: feed_version_infos
#
#  id                :integer          not null, primary key
#  statistics        :json
#  scheduled_service :json
#  filenames         :string           is an Array
#  feed_version_id   :integer
#  created_at        :datetime
#  updated_at        :datetime
#
# Indexes
#
#  index_feed_version_infos_on_feed_version_id  (feed_version_id)
#

class FeedVersionInfo < ActiveRecord::Base
  belongs_to :feed_version
  # belongs_to :feed, through: :feed_version, source_type: 'Feed'
end
