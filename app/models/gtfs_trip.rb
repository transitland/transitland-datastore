# == Schema Information
#
# Table name: gtfs_trips
#
#  id                    :integer          not null, primary key
#  trip_id               :string           not null
#  trip_headsign         :string           not null
#  trip_short_name       :string           not null
#  direction_id          :integer          not null
#  block_id              :string           not null
#  wheelchair_accessible :integer          not null
#  bikes_allowed         :integer          not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  feed_version_id       :integer          not null
#  route_id              :integer          not null
#  shape_id              :integer
#  stop_pattern_id       :integer          not null
#  service_id            :integer          not null
#
# Indexes
#
#  index_gtfs_trips_on_route_id         (route_id)
#  index_gtfs_trips_on_service_id       (service_id)
#  index_gtfs_trips_on_shape_id         (shape_id)
#  index_gtfs_trips_on_trip_headsign    (trip_headsign)
#  index_gtfs_trips_on_trip_id          (trip_id)
#  index_gtfs_trips_on_trip_short_name  (trip_short_name)
#  index_gtfs_trips_unique              (feed_version_id,trip_id) UNIQUE
#

class GTFSTrip < ActiveRecord::Base
  include GTFSEntity
  has_many :stop_times, class_name: 'GTFSStopTime', foreign_key: 'trip_id'
  has_many :stops, -> { distinct }, through: :stop_times
  
  def service
    c = GTFSCalendar.find_by(feed_version_id: feed_version_id, service_id: service_id) || GTFSCalendar.new(feed_version_id: feed_version_id, service_id: service_id)
    {
      id: c.id,
      service_id: c.service_id,
      start_date: c.start_date,
      end_date: c.end_date,
      exceptions: c.exceptions.map { |e| {id: e.id, date: e.date, exception_type: e.exception_type } } 
    }
  end


  belongs_to :route, class_name: 'GTFSRoute'
  belongs_to :feed_version
  belongs_to :entity, class_name: 'RouteStopPattern'
  belongs_to :shape, class_name: 'GTFSShape'
  validates :feed_version, presence: true, unless: :skip_association_validations
  validates :route, presence: true, unless: :skip_association_validations
  validates :service_id, presence: true
  validates :trip_id, presence: true

  def geometry
    shape.geometry
  end
end
