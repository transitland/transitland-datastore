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

class BaseStopTransfer < ActiveRecord::Base
  self.abstract_class = true
end


class StopTransfer < BaseStopTransfer
  include CurrentTrackedByChangeset
  self.table_name_prefix = 'current_'
  belongs_to :stop
  belongs_to :to_stop, class_name: 'Stop'
  current_tracked_by_changeset kind_of_model_tracked: :relationship
  validates :transfer_type, :stop, :destination, presence: true
end

class OldStopTransfer < BaseStopTransfer
  include OldTrackedByChangeset
  belongs_to :stop, polymorphic: true
  belongs_to :to_stop, polymorphic: true
end
