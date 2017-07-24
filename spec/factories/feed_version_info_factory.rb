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
#  index_feed_version_infos_on_feed_version_id           (feed_version_id)
#  index_feed_version_infos_on_feed_version_id_and_type  (feed_version_id,type) UNIQUE
#

FeedVersionInfo.connection

FactoryGirl.define do
  factory :feed_version_info do
    feed_version
  end

  factory :feed_version_info_conveyal_validation, class: FeedVersionInfoConveyalValidation, parent: :feed_version_info do
  end

  factory :feed_version_info_statistics, class: FeedVersionInfoStatistics, parent: :feed_version_info do
  end

end
