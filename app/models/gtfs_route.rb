# == Schema Information
#
# Table name: gtfs_routes
#
#  id               :integer          not null, primary key
#  route_id         :string           not null
#  route_short_name :string           not null
#  route_long_name  :string           not null
#  route_desc       :string
#  route_type       :integer          not null
#  route_url        :string
#  route_color      :string
#  route_text_color :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  feed_version_id  :integer          not null
#  entity_id        :integer
#  agency_id        :integer          not null
#
# Indexes
#
#  index_gtfs_routes_on_agency_id         (agency_id)
#  index_gtfs_routes_on_entity_id         (entity_id)
#  index_gtfs_routes_on_feed_version_id   (feed_version_id)
#  index_gtfs_routes_on_route_desc        (route_desc)
#  index_gtfs_routes_on_route_id          (route_id)
#  index_gtfs_routes_on_route_long_name   (route_long_name)
#  index_gtfs_routes_on_route_short_name  (route_short_name)
#  index_gtfs_routes_on_route_type        (route_type)
#  index_gtfs_routes_unique               (feed_version_id,route_id) UNIQUE
#

class GTFSRoute < ActiveRecord::Base
  has_many :trips, class_name: GTFSTrip, foreign_key: "route_id"
  belongs_to :agency, class_name: 'GTFSAgency'
  belongs_to :feed_version
  belongs_to :entity, class_name: 'Route'
end
