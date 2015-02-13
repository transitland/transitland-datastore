# == Schema Information
#
# Table name: stops
#
#  id                                 :integer          not null, primary key
#  onestop_id                         :string(255)
#  geometry                           :spatial          geometry, 4326
#  tags                               :hstore
#  created_at                         :datetime
#  updated_at                         :datetime
#  name                               :string(255)
#  created_or_updated_in_changeset_id :integer
#  destroyed_in_changeset_id          :integer
#  version                            :integer
#  current                            :boolean
#
# Indexes
#
#  index_stops_on_current          (current)
#  index_stops_on_onestop_id       (onestop_id)
#  stops_cu_in_changeset_id_index  (created_or_updated_in_changeset_id)
#  stops_d_in_changeset_id_index   (destroyed_in_changeset_id)
#

class Stop < ActiveRecord::Base
  include HasAOnestopId
  include IsAnEntityWithIdentifiers
  include TrackedByChangeset
  include HasAGeographicGeometry

  PER_PAGE = 50

  has_many :operators_serving_stop, dependent: :destroy
  has_many :operators, through: :operators_serving_stop

  def self.match_against_existing_or_initialize(attrs)
    if attrs.has_key?(:onestop_id) && attrs[:onestop_id].present?
      # TODO: update?
      return Stop.find_or_create_by(onestop_id: attrs[:onestop_id])
    end
    radius = 5 # TODO: move to config
    existing_stops = Stop.select{['stops.*', st_distance(geometry, attrs[:geometry]).as(distance)]}.where{st_dwithin(stops.geometry, attrs[:geometry], radius) & (name == attrs[:name]) }.order('distance')
    if existing_stops.count == 0
      return Stop.new(attrs)
    else
      return existing_stops.first
    end
  end

  before_save :clean_attributes

  private

  def clean_attributes
    self.name.strip! if self.name.present?
  end
end
