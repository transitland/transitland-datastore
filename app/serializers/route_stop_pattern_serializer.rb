# == Schema Information
#
# Table name: current_route_stop_patterns
#
#  id                                 :integer          not null, primary key
#  onestop_id                         :string
#  geometry                           :geography({:srid geometry, 4326
#  tags                               :hstore
#  stop_pattern                       :string           default([]), is an Array
#  version                            :integer
#  created_or_updated_in_changeset_id :integer
#  is_generated                       :boolean          default(FALSE)
#  is_modified                        :boolean          default(FALSE)
#  is_only_stop_points                :boolean          default(FALSE)
#  trips                              :string           default([]), is an Array
#  identifiers                        :string           default([]), is an Array
#  created_at                         :datetime         not null
#  updated_at                         :datetime         not null
#  route_id                           :integer
#
# Indexes
#
#  index_current_route_stop_patterns_on_identifiers  (identifiers)
#  index_current_route_stop_patterns_on_route_id     (route_id)
#

class RouteStopPatternSerializer < ApplicationSerializer
  attributes :onestop_id,
             :route_onestop_id,
             :stop_pattern,
             :geometry,
             :is_generated,
             :is_modified,
             :is_only_stop_points,
             :created_at,
             :updated_at,
             :trips,
             :tags
   def route_onestop_id
     object.route.onestop_id
   end
end
