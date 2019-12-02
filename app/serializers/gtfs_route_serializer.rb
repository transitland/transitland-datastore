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

class GTFSRouteSerializer < GTFSEntitySerializer
    attributes :route_id,
                :route_short_name,
                :route_long_name,
                :route_desc,
                :route_type,
                :route_type_desc,
                :route_url,
                :route_color,
                :route_text_color,
                :agency_id,
                :geometry_generated
                # :route_sort_order

    def route_type_desc
    end
end
  
