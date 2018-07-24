# == Schema Information
#
# Table name: gtfs_fare_rules
#
#  id              :integer          not null, primary key
#  fare_id         :string           not null
#  contains_id     :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  feed_version_id :integer          not null
#  route_id        :integer
#  origin_id       :integer
#  destination_id  :integer
#
# Indexes
#
#  index_gtfs_fare_rules_on_destination_id   (destination_id)
#  index_gtfs_fare_rules_on_fare_id          (fare_id)
#  index_gtfs_fare_rules_on_feed_version_id  (feed_version_id)
#  index_gtfs_fare_rules_on_origin_id        (origin_id)
#  index_gtfs_fare_rules_on_route_id         (route_id)
#

class GTFSFareRuleSerializer < GTFSEntitySerializer
end
  
