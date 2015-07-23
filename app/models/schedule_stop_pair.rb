# == Schema Information
#
# Table name: current_schedule_stop_pairs
#
#  id                                 :integer          not null, primary key
#  origin_id                          :integer
#  destination_id                     :integer
#  route_id                           :integer
#  trip                               :string
#  created_or_updated_in_changeset_id :integer
#  version                            :integer
#  trip_headsign                      :string
#  origin_arrival_time                :string
#  origin_departure_time              :string
#  destination_arrival_time           :string
#  destination_departure_time         :string
#  frequency_start_time               :string
#  frequency_end_time                 :string
#  frequency_headway_seconds          :string
#  tags                               :hstore
#  calendar                           :hstore
#  created_at                         :datetime         not null
#  updated_at                         :datetime         not null
#
# Indexes
#
#  c_ssp_cu_in_changeset                                     (created_or_updated_in_changeset_id)
#  c_ssp_origin_id_and_destination_id_and_route_id_and_trip  (origin_id,destination_id,route_id,trip) UNIQUE
#  index_current_schedule_stop_pairs_on_destination_id       (destination_id)
#  index_current_schedule_stop_pairs_on_origin_id            (origin_id)
#  index_current_schedule_stop_pairs_on_route_id             (route_id)
#  index_current_schedule_stop_pairs_on_trip                 (trip)
#

class BaseScheduleStopPair < ActiveRecord::Base
  self.abstract_class = true
end

class ScheduleStopPair < BaseScheduleStopPair
  self.table_name_prefix = 'current_'

  # Relations to stops and routes
  belongs_to :origin, class_name: "Stop"
  belongs_to :destination, class_name: "Stop"
  belongs_to :route

  validates :route, presence: true
  validates :destination, presence: true
  validates :route, presence: true
  validates :trip, presence: true

  def route_onestop_id=(value)
    self.route = Route.find_by(onestop_id: value)
  end

  def origin_onestop_id=(value)
    self.origin = Stop.find_by(onestop_id: value)
  end
 
  def destination_onestop_id=(value)
    self.destination = Stop.find_by(onestop_id: value)
  end

  # Tracked by changeset
  include CurrentTrackedByChangeset
  current_tracked_by_changeset({
    kind_of_model_tracked: :relationship,
    virtual_attributes: [:origin_onestop_id, :destination_onestop_id, :route_onestop_id]
  })
  def self.find_by_attributes(attrs = {})
    missing = [:origin_onestop_id, :destination_onestop_id, :route_onestop_id, :trip] - attrs.keys
    if missing.empty?
      origin = Stop.find_by_onestop_id!(attrs[:origin_onestop_id])
      destination = Stop.find_by_onestop_id!(attrs[:destination_onestop_id])
      route = Route.find_by_onestop_id!(attrs[:route_onestop_id])
      find_by(origin: origin, destination: destination, route: route, trip: attrs[:trip])
    else
      raise ArgumentError.new("Required arguments: #{missing.join(', ')}")
    end
  end
end

class OldScheduleStopPair < BaseScheduleStopPair
  include OldTrackedByChangeset
  belongs_to :stop, polymorphic: true
end
