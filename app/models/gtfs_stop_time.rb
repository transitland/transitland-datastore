# == Schema Information
#
# Table name: gtfs_stop_times
#
#  id                  :integer          not null, primary key
#  arrival_time        :integer          not null
#  departure_time      :integer          not null
#  stop_sequence       :integer          not null
#  stop_headsign       :string           not null
#  pickup_type         :integer          not null
#  drop_off_type       :integer          not null
#  shape_dist_traveled :float            not null
#  timepoint           :integer          not null
#  interpolated        :integer          default(0), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  feed_version_id     :integer          not null
#  trip_id             :integer          not null
#  stop_id             :integer          not null
#
# Indexes
#
#  index_gtfs_stop_times_on_feed_version_id_trip_id_stop_id  (feed_version_id,trip_id,stop_id)
#  index_gtfs_stop_times_on_stop_id                          (stop_id)
#  index_gtfs_stop_times_on_trip_id                          (trip_id)
#  index_gtfs_stop_times_unique                              (feed_version_id,trip_id,stop_sequence) UNIQUE
#

class GTFSStopTime < ActiveRecord::Base
  include GTFSEntity
  belongs_to :feed_version
  belongs_to :trip, class_name: 'GTFSTrip'
  belongs_to :stop, class_name: 'GTFSStop'
  belongs_to :destination, class_name: 'GTFSStop'
  belongs_to :trip, class_name: 'GTFSTrip'
  has_one :shape, :through => :trip
  validates :feed_version, presence: true, unless: :skip_association_validations
  validates :trip, presence: true, unless: :skip_association_validations
  validates :stop, presence: true, unless: :skip_association_validations
  validates :arrival_time, presence: true
  validates :departure_time, presence: true
  validates :stop_sequence, presence: true
  validates :interpolated, presence: true
end
