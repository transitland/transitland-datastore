# == Schema Information
#
# Table name: gtfs_routes
#
#  id               :integer          not null, primary key
#  route_id         :string           not null
#  route_short_name :string           not null
#  route_long_name  :string           not null
#  route_desc       :string           not null
#  route_type       :integer          not null
#  route_url        :string           not null
#  route_color      :string           not null
#  route_text_color :string           not null
#  route_sort_order :integer          not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  feed_version_id  :integer          not null
#  agency_id        :integer          not null
#
# Indexes
#
#  index_gtfs_routes_on_agency_id                  (agency_id)
#  index_gtfs_routes_on_feed_version_id_agency_id  (feed_version_id,id,agency_id)
#  index_gtfs_routes_on_route_desc                 (route_desc)
#  index_gtfs_routes_on_route_id                   (route_id)
#  index_gtfs_routes_on_route_long_name            (route_long_name)
#  index_gtfs_routes_on_route_short_name           (route_short_name)
#  index_gtfs_routes_on_route_type                 (route_type)
#  index_gtfs_routes_unique                        (feed_version_id,route_id) UNIQUE
#

class GTFSRoute < ActiveRecord::Base
  include GTFSEntity
  has_many :trips, class_name: GTFSTrip, foreign_key: "route_id"
  belongs_to :agency, class_name: 'GTFSAgency'
  belongs_to :feed_version
  belongs_to :entity, class_name: 'Route'
  validates :feed_version, presence: true, unless: :skip_association_validations
  validates :agency, presence: true, unless: :skip_association_validations
  validates :route_id, presence: true
  validates :route_type, presence: true
  validate { errors.add("route_short_name or route_long_name must be present") unless route_short_name.presence || route_long_name.presence }
end
