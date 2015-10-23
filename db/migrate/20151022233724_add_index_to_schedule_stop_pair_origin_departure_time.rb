class AddIndexToScheduleStopPairOriginDepartureTime < ActiveRecord::Migration
  def change
    add_index :current_schedule_stop_pairs, :origin_departure_time
  end
end
