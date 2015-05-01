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
#  identifiers                        :string           is an Array
#
# Indexes
#
#  c_route_cu_in_changeset              (created_or_updated_in_changeset_id)
#  index_current_routes_on_identifiers  (identifiers)
#  index_current_routes_on_operator_id  (operator_id)
#

FactoryGirl.define do
  factory :route do
    onestop_id { Faker::OnestopId.route }
    name { [
      '19 Polk',
      'N Judah',
      '522 Rapid'
    ].sample }
    version 1
    association :created_or_updated_in_changeset, factory: :changeset
  end
end
