# == Schema Information
#
# Table name: operators
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  tags       :hstore
#  created_at :datetime
#  updated_at :datetime
#  onestop_id :string(255)
#  geometry   :spatial          geometry, 4326
#
# Indexes
#
#  index_operators_on_onestop_id  (onestop_id) UNIQUE
#

FactoryGirl.define do
  factory :operator do
    name { Faker::Company.name }
    geometry { "POINT(#{rand(-124.4..-90.1)} #{rand(28.1..50.0095)})" }
  end
end
