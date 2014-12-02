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

class Operator < ActiveRecord::Base
  has_many :operator_serving_stops, dependent: :destroy
  has_many :stops, through: :operator_serving_stops

  validate :name, presence: true
end
