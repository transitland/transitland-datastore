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
#  route_stop_pattern_id              :integer
#  origin_dist_traveled               :float
#  destination_dist_traveled          :float
#  feed_id                            :integer
#  feed_version_id                    :integer
#  frequency_type                     :string
#  frequency_headway_seconds          :integer
#
# Indexes
#
#  current_schedule_stop_pairs64_created_or_updated_in_changes_idx  (created_or_updated_in_changeset_id)
#  current_schedule_stop_pairs64_destination_id_idx                 (destination_id)
#  current_schedule_stop_pairs64_feed_id_id_idx                     (feed_id,id)
#  current_schedule_stop_pairs64_feed_version_id_id_idx             (feed_version_id,id)
#  current_schedule_stop_pairs64_frequency_type_idx                 (frequency_type)
#  current_schedule_stop_pairs64_operator_id_id_idx                 (operator_id,id)
#  current_schedule_stop_pairs64_origin_departure_time_idx          (origin_departure_time)
#  current_schedule_stop_pairs64_origin_id_idx                      (origin_id)
#  current_schedule_stop_pairs64_route_id_idx                       (route_id)
#  current_schedule_stop_pairs64_route_stop_pattern_id_idx          (route_stop_pattern_id)
#  current_schedule_stop_pairs64_service_end_date_idx               (service_end_date)
#  current_schedule_stop_pairs64_service_start_date_idx             (service_start_date)
#  current_schedule_stop_pairs64_trip_idx                           (trip)
#  current_schedule_stop_pairs64_updated_at_idx                     (updated_at)
#

class ScheduleStopPairSerializer < ApplicationSerializer
  attributes :origin_onestop_id,
             :destination_onestop_id,
             :route_onestop_id,
             :route_stop_pattern_onestop_id,
             :operator_onestop_id,
             :feed_onestop_id,
             :feed_version_sha1,
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
             :origin_dist_traveled,
             :destination_dist_traveled,
             :service_start_date,
             :service_end_date,
             :service_added_dates,
             :service_except_dates,
             :service_days_of_week,
             :window_start,
             :window_end,
             :origin_timepoint_source,
             :destination_timepoint_source,
             :frequency_start_time,
             :frequency_end_time,
             :frequency_headway_seconds,
             :frequency_type,
             :created_at,
             :updated_at

  def feed_onestop_id
    object.feed.try(:onestop_id)
  end

  def feed_version_sha1
    object.feed_version.try(:sha1)
  end

  def origin_onestop_id
    object.origin.try(:onestop_id)
  end

  def destination_onestop_id
    object.destination.try(:onestop_id)
  end

  def route_onestop_id
    object.route.try(:onestop_id)
  end

  def route_stop_pattern_onestop_id
    object.route_stop_pattern.try(:onestop_id)
  end

  def operator_onestop_id
    object.operator.try(:onestop_id)
  end
end
