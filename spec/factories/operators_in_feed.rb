# == Schema Information
#
# Table name: operators_in_feed
#
#  id             :integer          not null, primary key
#  feed_id        :integer
#  operator_id    :integer
#  onestop_id     :string(255)
#  gtfs_agency_id :string(255)
#  created_at     :datetime
#  updated_at     :datetime
#
# Indexes
#
#  index_operators_in_feed_on_feed_id      (feed_id)
#  index_operators_in_feed_on_operator_id  (operator_id)
#

FactoryGirl.define do
  factory :operator_in_feed do
    feed
    # TODO: finish this factory
  end
end
