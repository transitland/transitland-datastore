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
#  timezone                           :string
#  last_conflated_at                  :datetime
#  type                               :string
#  parent_stop_id                     :integer
#
# Indexes
#
#  #c_stops_cu_in_changeset_id_index      (created_or_updated_in_changeset_id)
#  index_current_stops_on_geometry        (geometry)
#  index_current_stops_on_identifiers     (identifiers)
#  index_current_stops_on_onestop_id      (onestop_id)
#  index_current_stops_on_parent_stop_id  (parent_stop_id)
#  index_current_stops_on_tags            (tags)
#  index_current_stops_on_updated_at      (updated_at)
#

class StopStationSerializer < CurrentEntitySerializer
  attributes :onestop_id,
             :geometry,
             :name,
             :tags,
             :timezone,
             :created_at,
             :updated_at,
             :stop_egresses

  has_many :operators_serving_stop
  has_many :routes_serving_stop
  class StopPlatformSerializer < ActiveModel::Serializer
    attributes :onestop_id
  end
  class StopEgressSerializer < ActiveModel::Serializer
    attributes :onestop_id
  end
  def stop_egresses
    object.stop_egresses.presence || [StopEgress.new(onestop_id: "#{object.onestop_id}>")]
  end
  def stop_platforms
    object.stop_platforms.presence || [StopPlatform.new(onestop_id: "#{object.onestop_id}<")]
  end
  has_many :stop_platforms, serializer: StopPlatformSerializer
  has_many :stop_egresses, serializer: StopEgressSerializer
end
