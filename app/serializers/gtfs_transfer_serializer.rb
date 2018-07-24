# == Schema Information
#
# Table name: gtfs_transfers
#
#  id                :integer          not null, primary key
#  transfer_type     :integer          not null
#  min_transfer_time :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  feed_version_id   :integer          not null
#  from_stop_id      :integer          not null
#  to_stop_id        :integer          not null
#
# Indexes
#
#  index_gtfs_transfers_on_feed_version_id  (feed_version_id)
#  index_gtfs_transfers_on_from_stop_id     (from_stop_id)
#  index_gtfs_transfers_on_to_stop_id       (to_stop_id)
#

class GTFSTransferSerializer < GTFSEntitySerializer
end
  
