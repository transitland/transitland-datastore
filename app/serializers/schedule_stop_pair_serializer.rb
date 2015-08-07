
class ScheduleStopPairSerializer < ApplicationSerializer
  attributes :origin_onestop_id,
             :destination_onestop_id,
             :route_onestop_id,
             :trip,
             :trip_headsign,
             :origin_arrival_time,
             :origin_departure_time,
             :destination_arrival_time,
             :destination_departure_time,
             :service_start_date,
             :service_end_date,
             :service_added_dates,
             :service_except_dates,
             :service_days_of_week,
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
end
