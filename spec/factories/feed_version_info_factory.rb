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

FactoryGirl.define do
  factory :feed_version_info do
    feed_version
  end
end
