# == Schema Information
#
# Table name: current_stations
#
#  id                                 :integer          not null, primary key
#  type                               :string
#  onestop_id                         :string
#  name                               :string
#  last_conflated_at                  :datetime
#  tags                               :hstore
#  geometry                           :geography({:srid geometry, 4326
#  parent_station_id                  :integer
#  created_or_updated_in_changeset_id :integer
#  version                            :integer
#  created_at                         :datetime         not null
#  updated_at                         :datetime         not null
#
# Indexes
#
#  index_current_station_on_cu_in_changeset_id  (created_or_updated_in_changeset_id)
#  index_current_stations_on_parent_station_id  (parent_station_id)
#

require 'rails_helper'

RSpec.describe Station, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
