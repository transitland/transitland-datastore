# == Schema Information
#
# Table name: stops
#
#  id                                 :integer          not null, primary key
#  onestop_id                         :string(255)
#  geometry                           :spatial          geometry, 4326
#  tags                               :hstore
#  created_at                         :datetime
#  updated_at                         :datetime
#  name                               :string(255)
#  created_or_updated_in_changeset_id :integer
#  destroyed_in_changeset_id          :integer
#  version                            :integer
#  current                            :boolean
#
# Indexes
#
#  index_stops_on_current          (current)
#  index_stops_on_onestop_id       (onestop_id)
#  stops_cu_in_changeset_id_index  (created_or_updated_in_changeset_id)
#  stops_d_in_changeset_id_index   (destroyed_in_changeset_id)
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
