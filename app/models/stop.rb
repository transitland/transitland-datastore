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

class Stop < ActiveRecord::Base
  has_many :stop_identifiers, dependent: :destroy

  validates :onestop_id, presence: true # TODO: make this a more meaningful validation
end
