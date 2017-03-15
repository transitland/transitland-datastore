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

class FeedVersionInfo < ActiveRecord::Base
  has_one :feed_version
  has_one :feed, through: :feed_version, source_type: 'Feed'
end
