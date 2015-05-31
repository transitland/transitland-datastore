# == Schema Information
#
# Table name: current_stops
#
#  id                                 :integer          not null, primary key
#  onestop_id                         :string
#  geometry                           :geography({:srid geometry, 4326
#  tags                               :hstore
#  created_at                         :datetime
#  updated_at                         :datetime
#  name                               :string
#  created_or_updated_in_changeset_id :integer
#  version                            :integer
#  identifiers                        :string           default([]), is an Array
#
# Indexes
#
#  #c_stops_cu_in_changeset_id_index   (created_or_updated_in_changeset_id)
#  index_current_stops_on_identifiers  (identifiers)
#  index_current_stops_on_onestop_id   (onestop_id)
#  index_current_stops_on_tags         (tags)
#

class StopSerializer < CurrentEntitySerializer
  attributes :onestop_id,
             :geometry,
             :name,
             :tags,
             :created_at,
             :updated_at

  has_many :operators_serving_stop
  has_many :routes_serving_stop
end
