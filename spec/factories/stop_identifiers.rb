# == Schema Information
#
# Table name: stop_identifiers
#
#  id         :integer          not null, primary key
#  stop_id    :integer          not null
#  identifier :string(255)
#  created_at :datetime
#  updated_at :datetime
#  tags       :hstore
#
# Indexes
#
#  index_stop_identifiers_on_stop_id  (stop_id)
#

FactoryGirl.define do
  factory :stop_identifier do
    stop
    identifier { ['19th Avenue & Holloway St', '390'].sample }
  end
end
