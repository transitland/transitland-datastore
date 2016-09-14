# == Schema Information
#
# Table name: current_stops
#
#  id                                 :integer          not null, primary key
#  onestop_id                         :string
#  geometry                           :geography({:srid geometry, 4326
#  tags                               :hstore
#  created_at                         :datetime
#  updated_at                         :datetime
#  name                               :string
#  created_or_updated_in_changeset_id :integer
#  version                            :integer
#  identifiers                        :string           default([]), is an Array
#  timezone                           :string
#  last_conflated_at                  :datetime
#  type                               :string
#  parent_stop_id                     :integer
#  osm_way_id                         :integer
#
# Indexes
#
#  #c_stops_cu_in_changeset_id_index      (created_or_updated_in_changeset_id)
#  index_current_stops_on_geometry        (geometry)
#  index_current_stops_on_identifiers     (identifiers)
#  index_current_stops_on_onestop_id      (onestop_id) UNIQUE
#  index_current_stops_on_parent_stop_id  (parent_stop_id)
#  index_current_stops_on_tags            (tags)
#  index_current_stops_on_updated_at      (updated_at)
#

FactoryGirl.define do
  factory :stop_platform, class: StopPlatform, parent: :stop do
    association :parent_stop, factory: :stop
  end
end
