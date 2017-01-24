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
#  osm_way_id                         :integer
#  edited_attributes                  :string           default([]), is an Array
#  wheelchair_boarding                :boolean
#
# Indexes
#
#  #c_stops_cu_in_changeset_id_index           (created_or_updated_in_changeset_id)
#  index_current_stops_on_geometry             (geometry)
#  index_current_stops_on_identifiers          (identifiers)
#  index_current_stops_on_onestop_id           (onestop_id) UNIQUE
#  index_current_stops_on_parent_stop_id       (parent_stop_id)
#  index_current_stops_on_tags                 (tags)
#  index_current_stops_on_updated_at           (updated_at)
#  index_current_stops_on_wheelchair_boarding  (wheelchair_boarding)
#

class StopEgress < Stop
  current_tracked_by_changeset({
    kind_of_model_tracked: :onestop_entity,
    virtual_attributes: [
      :served_by,
      :not_served_by,
      :identified_by,
      :not_identified_by,
      :parent_stop_onestop_id,
      :includes_stop_transfers,
      :does_not_include_stop_transfers,
      :add_imported_from_feeds,
      :not_imported_from_feeds
    ],
    protected_attributes: [
      :identifiers,
      :last_conflated_at,
      :type
    ]
  })
  belongs_to :parent_stop, class_name: 'Stop'
  validates :parent_stop, presence: true

  def update_parent_stop(changeset)
    (self.parent_stop = Stop.find_by_onestop_id!(self.parent_stop_onestop_id)) if self.parent_stop_onestop_id
  end

  def after_create_making_history(changeset)
    update_parent_stop(changeset)
    super(changeset)
  end

  def before_update_making_history(changeset)
    update_parent_stop(changeset)
    super(changeset)
  end
end

class OldStopEgress < OldStop
end
