# == Schema Information
#
# Table name: operators
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  tags       :hstore
#  created_at :datetime
#  updated_at :datetime
#

FactoryGirl.define do
  factory :operator do
    name { Faker::Company.name }
  end
end
