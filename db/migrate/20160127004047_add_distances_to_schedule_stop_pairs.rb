class AddDistancesToScheduleStopPairs < ActiveRecord::Migration
  def change
    add_column :current_schedule_stop_pairs, :origin_dist_traveled, :float
    add_column :old_schedule_stop_pairs, :origin_dist_traveled, :float
    add_column :current_schedule_stop_pairs, :destination_dist_traveled, :float
    add_column :old_schedule_stop_pairs, :destination_dist_traveled, :float
  end
end
