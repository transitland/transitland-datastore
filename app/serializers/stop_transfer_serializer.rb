# == Schema Information
#
# Table name: current_stop_transfers
#
#  id                                 :integer          not null, primary key
#  connection_type                    :string
#  tags                               :hstore
#  stop_id                            :integer
#  origin_id                          :integer
#  destination_id                     :integer
#  created_or_updated_in_changeset_id :integer
#  version                            :integer
#  created_at                         :datetime
#  updated_at                         :datetime
#
# Indexes
#
#  index_current_stop_transfers_on_connection_type  (connection_type)
#  index_current_stop_transfers_on_destination_id   (destination_id)
#  index_current_stop_transfers_on_origin_id        (origin_id)
#  index_current_stop_transfers_on_stop_id          (stop_id)
#

class StopTransferSerializer < ApplicationSerializer
  attributes :connection_type,
             :destination_onestop_id,
             :tags

  def destination_onestop_id
    object.destination.onestop_id
  end

end
