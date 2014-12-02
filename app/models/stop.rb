# == Schema Information
#
# Table name: stops
#
#  id         :integer          not null, primary key
#  onestop_id :string(255)
#  geometry   :spatial          geometry, 4326
#  tags       :hstore
#  created_at :datetime
#  updated_at :datetime
#  name       :string(255)
#
# Indexes
#
#  index_stops_on_onestop_id  (onestop_id)
#

class Stop < ActiveRecord::Base
  include OnestopId

  PER_PAGE = 50

  GEOFACTORY = RGeo::Geographic.simple_mercator_factory #(srid: 4326) # TODO: double check this
  set_rgeo_factory_for_column :geometry, GEOFACTORY

  has_many :stop_identifiers, dependent: :destroy
  has_many :operator_serving_stops, dependent: :destroy
  has_many :operators, through: :operator_serving_stops

  def self.find_by_onestop_id!(onestop_id)
    # TODO: make this case insensitive
    Stop.find_by!(onestop_id: onestop_id)
  end

  def self.match_against_existing_stop_or_create(attrs)
    if attrs.has_key?(:onestop_id) && attrs[:onestop_id].present?
      # TODO: update?
      return Stop.find_or_create_by(onestop_id: attrs[:onestop_id])
    end
    radius = 5 # TODO: move to config
    existing_stops = Stop.select{['stops.*', st_distance(geometry, attrs[:geometry]).as(distance)]}.where{st_dwithin(stops.geometry, attrs[:geometry], radius) & (name == attrs[:name]) }.order('distance')
    if existing_stops.count == 0
      return Stop.create(attrs)
    else
      # TODO: update attributes
      return existing_stops.first
    end
  end

  before_validation :set_onestop_id
  before_save :clean_attributes

  private

  def set_onestop_id
    self.onestop_id ||= generate_unique_onestop_id
  end

  def clean_attributes
    self.name.strip! if self.name.present?
  end
end
