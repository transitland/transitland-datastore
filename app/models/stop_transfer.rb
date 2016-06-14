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

class BaseStopTransfer < ActiveRecord::Base
  self.abstract_class = true
end


class StopTransfer < BaseStopTransfer
  include CurrentTrackedByChangeset
  self.table_name_prefix = 'current_'
  belongs_to :stop
  belongs_to :to_stop, class_name: 'Stop'
  current_tracked_by_changeset kind_of_model_tracked: :relationship
  validates :transfer_type, :stop, :to_stop, presence: true

  extend Enumerize
  enumerize :transfer_type, in: [
      :recommended,
      :timed,
      :min_transfer_time,
      :invalid
    ]

  GTFS_TRANSFER_TYPE = {
    "0" => :recommended,
    "1" => :timed,
    "2" => :min_transfer_time,
    "3" => :invalid
  }
end

class OldStopTransfer < BaseStopTransfer
  include OldTrackedByChangeset
  belongs_to :stop, polymorphic: true
  belongs_to :to_stop, polymorphic: true
end
