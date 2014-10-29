#  id         :integer          not null, primary key
#  onestop_id :string(255)
#  geometry   :spatial          geometry, 4326
#  codes      :string(255)      is an Array
#  names      :string(255)      is an Array
#  tags       :hstore
#  created_at :datetime
#  updated_at :datetime

class StopSerializer < ApplicationSerializer
  attributes :onestop_id,
             :geometry,
             :name,
             :tags,
             :created_at,
             :updated_at,
             :stop_identifiers
end
