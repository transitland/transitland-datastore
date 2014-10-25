# == Schema Information
#
# Table name: stops
#
#  id         :integer          not null, primary key
#  onestop_id :string(255)
#  geometry   :spatial          geometry, 4326
#  codes      :string(255)      is an Array
#  names      :string(255)      is an Array
#  tags       :hstore
#  created_at :datetime
#  updated_at :datetime
#

FactoryGirl.define do
  factory :stop do
    sequence(:onestop_id) { |n| "ntd9015-#{n}" }
    geometry { "POINT(#{rand(-124.4096..-114.1308)} #{rand(32.5343..42.0095)})" }
    names { [
      ['C. Chavez St & Florida St'],
      ['Metro Embarcadero Station', 'Embarcadero'],
      ['West Portal/Sloat/St Francis Circle']
    ].sample }
    codes { [
      ['CChavez'],
      ['EMB'],
      ['WestPort']
    ].sample }
  end
end
