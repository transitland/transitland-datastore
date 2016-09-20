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
#  identifiers                        :string           default([]), is an Array
#  vehicle_type                       :integer
#  color                              :string
#
# Indexes
#
#  c_route_cu_in_changeset               (created_or_updated_in_changeset_id)
#  index_current_routes_on_geometry      (geometry)
#  index_current_routes_on_identifiers   (identifiers)
#  index_current_routes_on_onestop_id    (onestop_id) UNIQUE
#  index_current_routes_on_operator_id   (operator_id)
#  index_current_routes_on_tags          (tags)
#  index_current_routes_on_updated_at    (updated_at)
#  index_current_routes_on_vehicle_type  (vehicle_type)
#

FactoryGirl.define do
  factory :route do
    onestop_id { Faker::OnestopId.route }
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

  factory :route_bart, class: Route do
    onestop_id { 'r-9q8y-richmond~dalycity~millbrae' }
    name { 'Richmond - Daly City/Millbrae'  }
    vehicle_type { 1 }
    version 1
    association :created_or_updated_in_changeset, factory: :changeset
    association :operator
  end
end
