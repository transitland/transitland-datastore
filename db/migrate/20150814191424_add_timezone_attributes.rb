class AddTimezoneAttributes < ActiveRecord::Migration
  def change
    # Add timezone as model attribute to Stops, Operators, ScheduleStopPairs.
    # Current
    add_column :current_stops, :timezone, :string
    add_column :current_operators, :timezone, :string
    add_column :current_schedule_stop_pairs, :origin_timezone, :string
    add_column :current_schedule_stop_pairs, :destination_timezone, :string
    # Old
    add_column :old_stops, :timezone, :string
    add_column :old_operators, :timezone, :string
    add_column :old_schedule_stop_pairs, :origin_timezone, :string
    add_column :old_schedule_stop_pairs, :destination_timezone, :string
  end
end
