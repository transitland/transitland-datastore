# == Schema Information
#
# Table name: stop_identifiers
#
#  id              :integer          not null, primary key
#  stop_id         :integer
#  identifier_type :string(255)
#  identifier      :string(255)
#  created_at      :datetime
#  updated_at      :datetime
#
# Indexes
#
#  index_stop_identifiers_on_stop_id  (stop_id)
#

FactoryGirl.define do
  factory :stop_identifier do
    stop
    identifier { ['19th Avenue & Holloway St', '390'].sample }
    identifier_type { ['GTFS stop_name', 'GTFS stop_id'].sample }
  end
end
