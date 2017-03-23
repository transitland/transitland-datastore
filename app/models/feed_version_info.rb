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

class FeedVersionInfo < ActiveRecord::Base
  belongs_to :feed_version
end

class FeedVersionInfoStatistics < FeedVersionInfo
end

class FeedVersionInfoConveyalValidation < FeedVersionInfo
end

FeedVersionInfo.connection
