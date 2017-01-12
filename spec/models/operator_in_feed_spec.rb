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

