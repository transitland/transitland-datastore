# == Schema Information
#
# Table name: gtfs_stops
#
#  id                  :integer          not null, primary key
#  stop_id             :string           not null
#  stop_code           :string           not null
#  stop_name           :string           not null
#  stop_desc           :string           not null
#  zone_id             :string           not null
#  stop_url            :string           not null
#  location_type       :integer          not null
#  stop_timezone       :string           not null
#  wheelchair_boarding :integer          not null
#  geometry            :geography({:srid not null, point, 4326
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  feed_version_id     :integer          not null
#  parent_station      :integer
#  level_id            :integer          not null
#
# Indexes
#
#  index_gtfs_stops_on_geometry        (geometry) USING gist
#  index_gtfs_stops_on_location_type   (location_type)
#  index_gtfs_stops_on_parent_station  (parent_station)
#  index_gtfs_stops_on_stop_code       (stop_code)
#  index_gtfs_stops_on_stop_desc       (stop_desc)
#  index_gtfs_stops_on_stop_id         (stop_id)
#  index_gtfs_stops_on_stop_name       (stop_name)
#  index_gtfs_stops_unique             (feed_version_id,stop_id) UNIQUE
#

class GTFSStop < ActiveRecord::Base
  include GTFSEntity
  include HasAGeographicGeometry
  has_many :stop_times, class_name: GTFSStopTime, foreign_key: "stop_id"
  has_many :gtfs_shapes
  belongs_to :feed_version
  belongs_to :entity, class_name: 'Stop'
  validates :feed_version, presence: true, unless: :skip_association_validations
  validates :stop_id, presence: true
  validates :stop_name, presence: true
  validates :geometry, presence: true

  def stop_lat
    self[:geometry].lat
  end

  def stop_lon
    self[:geometry].lon
  end

end
