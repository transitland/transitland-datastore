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
#  timezone                           :string
#  last_conflated_at                  :datetime
#  type                               :string
#  parent_stop_id                     :integer
#  osm_way_id                         :integer
#  edited_attributes                  :string           default([]), is an Array
#  wheelchair_boarding                :boolean
#  directionality                     :integer
#  geometry_reversegeo                :geography({:srid point, 4326
#
# Indexes
#
#  #c_stops_cu_in_changeset_id_index           (created_or_updated_in_changeset_id)
#  index_current_stops_on_geometry             (geometry) USING gist
#  index_current_stops_on_geometry_reversegeo  (geometry_reversegeo) USING gist
#  index_current_stops_on_onestop_id           (onestop_id) UNIQUE
#  index_current_stops_on_parent_stop_id       (parent_stop_id)
#  index_current_stops_on_tags                 (tags)
#  index_current_stops_on_updated_at           (updated_at)
#  index_current_stops_on_wheelchair_boarding  (wheelchair_boarding)
#

class StopPlatform < Stop
  current_tracked_by_changeset({
    kind_of_model_tracked: :onestop_entity,
    virtual_attributes: [
      :served_by,
      :not_served_by,
      :parent_stop_onestop_id,
      :includes_stop_transfers,
      :does_not_include_stop_transfers,
      :add_imported_from_feeds,
      :not_imported_from_feeds
    ],
    protected_attributes: [
      :last_conflated_at,
      :type
    ]
  })
  # Temporary
  attr_accessor :platform_name

  def generate_onestop_id
    fail Exception.new('geometry required') if geometry.nil?
    fail Exception.new('name required') if name.nil?
    fail Exception.new('platform_name required') if platform_name.nil?
    fail Exception.new('parent_stop required') if parent_stop.nil?
    platform_name = self.platform_name.gsub(/[\>\<]/, '')
    parent_onestop_id = OnestopId::StopOnestopId.new(
      string: parent_stop.onestop_id || parent_stop.generate_onestop_id
    )
    onestop_id = OnestopId::StopOnestopId.new(
      geohash: parent_onestop_id.geohash,
      name: "#{parent_onestop_id.name}<#{platform_name}"
    )
    onestop_id.validate!
    onestop_id.to_s
  end
end

class OldStopPlatform < OldStop
end
