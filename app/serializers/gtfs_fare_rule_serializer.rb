# == Schema Information
#
# Table name: gtfs_fare_rules
#
#  id              :integer          not null, primary key
#  origin_id       :string           not null
#  destination_id  :string           not null
#  contains_id     :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  feed_version_id :integer          not null
#  route_id        :integer
#  fare_id         :integer
#
# Indexes
#
#  index_gtfs_fare_rules_on_fare_id          (fare_id)
#  index_gtfs_fare_rules_on_feed_version_id  (feed_version_id)
#  index_gtfs_fare_rules_on_route_id         (route_id)
#

class GTFSFareRuleSerializer < GTFSEntitySerializer
    attributes :fare_id, :contains_id, :route_id, :origin_id, :destination_id
end
  
