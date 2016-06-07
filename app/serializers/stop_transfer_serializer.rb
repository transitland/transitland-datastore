# == Schema Information
#
# Table name: current_stop_transfers
#
#  id                                 :integer          not null, primary key
#  transfer_type                      :string
#  min_transfer_time                  :integer
#  tags                               :hstore
#  stop_id                            :integer
#  to_stop_id                         :integer
#  created_or_updated_in_changeset_id :integer
#  version                            :integer
#  created_at                         :datetime
#  updated_at                         :datetime
#
# Indexes
#
#  index_current_stop_transfers_on_min_transfer_time  (min_transfer_time)
#  index_current_stop_transfers_on_stop_id            (stop_id)
#  index_current_stop_transfers_on_to_stop_id         (to_stop_id)
#  index_current_stop_transfers_on_transfer_type      (transfer_type)
#

class StopTransferSerializer < ApplicationSerializer
  attributes :transfer_type,
             :to_stop_onestop_id,
             :min_transfer_time,
             :tags

  def to_stop_onestop_id
    object.to_stop.onestop_id
  end

end
