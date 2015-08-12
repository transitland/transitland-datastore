class AddTripDetailsToScheduleStopPair < ActiveRecord::Migration
  def change
    # Current
    add_column :current_schedule_stop_pairs, :block_id, :string
    add_column :current_schedule_stop_pairs, :trip_short_name, :string
    add_column :current_schedule_stop_pairs, :wheelchair_accessible, :integer
    add_column :current_schedule_stop_pairs, :bikes_allowed, :integer
    add_column :current_schedule_stop_pairs, :pickup_type, :integer
    add_column :current_schedule_stop_pairs, :drop_off_type, :integer
    add_column :current_schedule_stop_pairs, :timepoint, :integer
    add_column :current_schedule_stop_pairs, :shape_dist_traveled, :float
    # Old
    add_column :old_schedule_stop_pairs, :block_id, :string
    add_column :old_schedule_stop_pairs, :trip_short_name, :string
    add_column :old_schedule_stop_pairs, :wheelchair_accessible, :integer
    add_column :old_schedule_stop_pairs, :bikes_allowed, :integer
    add_column :old_schedule_stop_pairs, :pickup_type, :integer
    add_column :old_schedule_stop_pairs, :drop_off_type, :integer
    add_column :old_schedule_stop_pairs, :timepoint, :integer
    add_column :old_schedule_stop_pairs, :shape_dist_traveled, :float
  end
end
