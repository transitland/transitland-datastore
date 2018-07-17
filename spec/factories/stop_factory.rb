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
#  timezone                           :string
#  last_conflated_at                  :datetime
#  type                               :string
#  parent_stop_id                     :integer
#  osm_way_id                         :integer
#  edited_attributes                  :string           default([]), is an Array
#  wheelchair_boarding                :boolean
#  directionality                     :integer
#  geometry_reversegeo                :geography({:srid point, 4326
#
# Indexes
#
#  #c_stops_cu_in_changeset_id_index           (created_or_updated_in_changeset_id)
#  index_current_stops_on_geometry             (geometry) USING gist
#  index_current_stops_on_geometry_reversegeo  (geometry_reversegeo) USING gist
#  index_current_stops_on_onestop_id           (onestop_id) UNIQUE
#  index_current_stops_on_parent_stop_id       (parent_stop_id)
#  index_current_stops_on_tags                 (tags)
#  index_current_stops_on_updated_at           (updated_at)
#  index_current_stops_on_wheelchair_boarding  (wheelchair_boarding)
#

FactoryGirl.define do
  factory :stop do
    onestop_id { Faker::OnestopId.stop }
    geometry { "POINT(#{rand(-124.4096..-114.1308)} #{rand(32.5343..42.0095)})" }
    timezone 'America/Los_Angeles'
    name { [
      'C. Chavez St & Florida St',
      'Metro Embarcadero Station',
      'West Portal/Sloat/St Francis Circle'
    ].sample }
    version 1
    association :created_or_updated_in_changeset, factory: :changeset
  end

  factory :old_stop, parent: :stop, class: OldStop do
    action 'destroy'
  end

  factory :stop_richmond, parent: :stop, class: Stop do
    onestop_id 's-9q8zzf1nks-richmond'
    geometry { "POINT(-122.353165 37.936887)" }
    timezone 'America/Los_Angeles'
    name 'Richmond'
  end

  factory :stop_richmond_offset, parent: :stop, class: Stop do
    onestop_id 's-9q8zzf1nks-richmond'
    geometry { "POINT(-122.350721 37.952326)" }
    timezone 'America/Los_Angeles'
    name 'Richmond'
  end

  factory :stop_millbrae, parent: :stop, class: Stop do
    onestop_id 's-9q8vzhbf8h-millbrae'
    geometry { "POINT(-122.38666 37.599787)" }
    timezone 'America/Los_Angeles'
    name 'Millbrae'
  end
end
