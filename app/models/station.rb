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

class BaseStation < ActiveRecord::Base
  self.abstract_class = true
  attr_accessor :served_by, :not_served_by
end

class Station < BaseStation
  self.table_name_prefix = 'current_'

  GEOHASH_PRECISION = 10

  # include HasAOnestopId
  include HasAGeographicGeometry
  include CurrentTrackedByChangeset

  # Station relations
  has_many :station_entrances, class_name: 'StationEntrance', foreign_key: :parent_station_id
  has_many :station_platforms, class_name: 'StationPlatform', foreign_key: :parent_station_id
  has_many :stops
end

class StationEntrance < Station
  belongs_to :parent_station, class_name: 'Station'
end

class StationPlatform < Station
  belongs_to :parent_station, class_name: 'Station'
end

class OldStation < BaseStation
  include OldTrackedByChangeset
  include HasAGeographicGeometry
end
