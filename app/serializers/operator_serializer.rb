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

class OperatorSerializer < EntitySerializer
  attributes :name,
             :onestop_id,
             :geometry,
             :tags,
             :created_at,
             :updated_at
end
