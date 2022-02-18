# == Schema Information
#
# Table name: current_operators_in_feed
#
#  id                                 :integer          not null, primary key
#  gtfs_agency_id                     :string
#  version                            :integer
#  created_at                         :datetime
#  updated_at                         :datetime
#  operator_id                        :integer
#  feed_id                            :integer
#  created_or_updated_in_changeset_id :integer
#
# Indexes
#
#  current_oif                                     (created_or_updated_in_changeset_id)
#  index_current_operators_in_feed_on_feed_id      (feed_id)
#  index_current_operators_in_feed_on_operator_id  (operator_id)
#

class OperatorInFeedSerializer < ApplicationSerializer
  attributes :gtfs_agency_id,
             :operator_onestop_id,
             :feed_onestop_id,
             :operator_url,
             :feed_url

  def operator_onestop_id
    object.operator.try(:onestop_id) || object.try(:resolved_onestop_id)
  end

  def feed_onestop_id
    object.feed.try(:onestop_id)
  end

  def operator_url
    if object.operator.try(:persisted?)
      api_v1_operator_url(object.operator.onestop_id)
    elsif object.try(:resolved_onestop_id).present?
      "https://transit.land/api/v2/rest/operators/#{resolved_onestop_id}"
    end
  end

  def feed_url
    api_v1_feed_url(object.feed.onestop_id) if object.feed.try(:persisted?)
  end
end
