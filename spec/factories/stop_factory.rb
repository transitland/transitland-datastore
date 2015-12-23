# == Schema Information
#
# Table name: current_stops
#
#  id                                 :integer          not null, primary key
#  geometry                           :geography({:srid geometry, 4326
#  created_at                         :datetime
#  updated_at                         :datetime
#  name                               :string
#  created_or_updated_in_changeset_id :integer
#  version                            :integer
#  timezone                           :string
#  last_conflated_at                  :datetime
#  identifier                         :string
#  url                                :string
#  zone                               :string
#  code                               :string
#  description                        :string
#  wheelchair_boarding                :integer
#  location_type                      :integer
#  station_id                         :integer
#  parent_stop_id                     :integer
#
# Indexes
#
#  #c_stops_cu_in_changeset_id_index      (created_or_updated_in_changeset_id)
#  index_current_stops_on_geometry        (geometry)
#  index_current_stops_on_parent_stop_id  (parent_stop_id)
#  index_current_stops_on_station_id      (station_id)
#  index_current_stops_on_updated_at      (updated_at)
#

FactoryGirl.define do
  factory :stop do
    onestop_id { Faker::OnestopId.stop }
    geometry { "POINT(#{rand(-124.4096..-114.1308)} #{rand(32.5343..42.0095)})" }
    name { [
      'C. Chavez St & Florida St',
      'Metro Embarcadero Station',
      'West Portal/Sloat/St Francis Circle'
    ].sample }
    version 1
    association :created_or_updated_in_changeset, factory: :changeset
  end
end
