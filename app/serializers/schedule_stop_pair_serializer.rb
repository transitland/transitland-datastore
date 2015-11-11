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
#  service_start_date                 :date
#  service_end_date                   :date
#  service_added_dates                :date             default([]), is an Array
#  service_except_dates               :date             default([]), is an Array
#  service_days_of_week               :boolean          default([]), is an Array
#  created_at                         :datetime         not null
#  updated_at                         :datetime         not null
#  block_id                           :string
#  trip_short_name                    :string
#  shape_dist_traveled                :float
#  origin_timezone                    :string
#  destination_timezone               :string
#  window_start                       :string
#  window_end                         :string
#  origin_timepoint_source            :string
#  destination_timepoint_source       :string
#  operator_id                        :integer
#  wheelchair_accessible              :boolean
#  bikes_allowed                      :boolean
#  pickup_type                        :string
#  drop_off_type                      :string
#  active                             :boolean
#
# Indexes
#
#  c_ssp_cu_in_changeset                                       (created_or_updated_in_changeset_id)
#  c_ssp_destination                                           (destination_id)
#  c_ssp_origin                                                (origin_id)
#  c_ssp_route                                                 (route_id)
#  c_ssp_service_end_date                                      (service_end_date)
#  c_ssp_service_start_date                                    (service_start_date)
#  c_ssp_trip                                                  (trip)
#  index_current_schedule_stop_pairs_on_active                 (active)
#  index_current_schedule_stop_pairs_on_operator_id            (operator_id)
#  index_current_schedule_stop_pairs_on_origin_departure_time  (origin_departure_time)
#  index_current_schedule_stop_pairs_on_updated_at             (updated_at)
#

class ScheduleStopPairSerializer < ApplicationSerializer
  attributes :origin_onestop_id,
             :destination_onestop_id,
             :route_onestop_id,
             :operator_onestop_id,
             :origin_timezone,
             :destination_timezone,
             :trip,
             :trip_headsign,
             :block_id,
             :trip_short_name,
             :wheelchair_accessible,
             :bikes_allowed,
             :pickup_type,
             :drop_off_type,
             :shape_dist_traveled,
             :origin_arrival_time,
             :origin_departure_time,
             :destination_arrival_time,
             :destination_departure_time,
             :service_start_date,
             :service_end_date,
             :service_added_dates,
             :service_except_dates,
             :service_days_of_week,
             :window_start,
             :window_end,
             :origin_timepoint_source,
             :destination_timepoint_source,
             :created_at,
             :updated_at

  def origin_onestop_id
    object.origin.try(:onestop_id)
  end

  def destination_onestop_id
    object.destination.try(:onestop_id)
  end

  def route_onestop_id
    object.route.try(:onestop_id)
  end

  def operator_onestop_id
    object.operator.try(:onestop_id)
  end
end
