# == Schema Information
#
# Table name: current_routes
#
#  id                                 :integer          not null, primary key
#  onestop_id                         :string
#  name                               :string
#  tags                               :hstore
#  operator_id                        :integer
#  created_or_updated_in_changeset_id :integer
#  version                            :integer
#  created_at                         :datetime
#  updated_at                         :datetime
#  geometry                           :geography({:srid geometry, 4326
#  vehicle_type                       :integer
#  color                              :string
#  edited_attributes                  :string           default([]), is an Array
#  wheelchair_accessible              :string           default("unknown")
#  bikes_allowed                      :string           default("unknown")
#
# Indexes
#
#  c_route_cu_in_changeset                        (created_or_updated_in_changeset_id)
#  index_current_routes_on_bikes_allowed          (bikes_allowed)
#  index_current_routes_on_geometry               (geometry) USING gist
#  index_current_routes_on_onestop_id             (onestop_id) UNIQUE
#  index_current_routes_on_operator_id            (operator_id)
#  index_current_routes_on_tags                   (tags)
#  index_current_routes_on_updated_at             (updated_at)
#  index_current_routes_on_vehicle_type           (vehicle_type)
#  index_current_routes_on_wheelchair_accessible  (wheelchair_accessible)
#

FactoryGirl.define do
  factory :route do
    onestop_id { Faker::OnestopId.route }
    geometry { {
      type: 'MultiLineString',
      coordinates: [
        [[-73.87, 40.88],[-73.97, 40.76],[-73.94, 40.68],[-73.95, 40.61]],
        [[-74.18, 40.81],[-74.00, 40.83],[-73.94, 40.79],[-73.80, 40.75]]
      ]
    } }
    name { [
      '19 Polk',
      'N Judah',
      '522 Rapid'
    ].sample }
    vehicle_type { [0,1,2,3,4,5,6,7,100,101,800,1700].sample }
    version 1
    association :created_or_updated_in_changeset, factory: :changeset
    association :operator
  end

  factory :route_bart, parent: :route, class: Route do
    onestop_id { 'r-9q8y-richmond~dalycity~millbrae' }
    name { 'Richmond - Daly City/Millbrae'  }
    vehicle_type { 1 }
    version 1
  end
end
