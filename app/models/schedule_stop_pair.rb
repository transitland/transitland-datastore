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
#  service_start_date                 :string
#  service_end_date                   :string
#  service_sunday                     :boolean
#  service_monday                     :boolean
#  service_tuesday                    :boolean
#  service_wednesday                  :boolean
#  service_thursday                   :boolean
#  service_friday                     :boolean
#  service_saturday                   :boolean
#  service_added                      :string           default([]), is an Array
#  service_except                     :string           default([]), is an Array
#  created_at                         :datetime         not null
#  updated_at                         :datetime         not null
#
# Indexes
#
#  c_ssp_cu_in_changeset     (created_or_updated_in_changeset_id)
#  c_ssp_destination         (destination_id)
#  c_ssp_origin              (origin_id)
#  c_ssp_route               (route_id)
#  c_ssp_service_end_date    (service_end_date)
#  c_ssp_service_start_date  (service_start_date)
#  c_ssp_trip                (trip)
#

class BaseScheduleStopPair < ActiveRecord::Base
  self.abstract_class = true
  PER_PAGE = 50
end

class ScheduleStopPair < BaseScheduleStopPair
  self.table_name_prefix = 'current_'

  # Relations to stops and routes
  belongs_to :origin, class_name: "Stop"
  belongs_to :destination, class_name: "Stop"
  belongs_to :route

  # Required relations and attributes
  validates :route, presence: true
  validates :destination, presence: true
  validates :route, presence: true
  validates :trip, presence: true

  # Handle mapping from onestop_id to id
  def route_onestop_id=(value)
    self.route_id = Route.where(onestop_id: value).pluck(:id).first
  end

  def origin_onestop_id=(value)
    self.origin_id = Stop.where(onestop_id: value).pluck(:id).first
  end
 
  def destination_onestop_id=(value)
    self.destination_id = Stop.where(onestop_id: value).pluck(:id).first
  end

  # Tracked by changeset
  include CurrentTrackedByChangeset
  current_tracked_by_changeset({
    kind_of_model_tracked: :relationship,
    virtual_attributes: [:origin_onestop_id, :destination_onestop_id, :route_onestop_id]
  })
  def self.find_by_attributes(attrs = {})
    if attrs[:id].present?
      find(attrs[:id])
    end    
  end
end

class OldScheduleStopPair < BaseScheduleStopPair
  include OldTrackedByChangeset
  belongs_to :stop, polymorphic: true
end
