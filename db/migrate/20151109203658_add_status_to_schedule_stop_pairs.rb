class AddStatusToScheduleStopPairs < ActiveRecord::Migration
  def change
  	add_column :current_schedule_stop_pairs, :active, :boolean
  	add_column :old_schedule_stop_pairs, :active, :boolean
  	add_index :current_schedule_stop_pairs, :active
  	add_index :old_schedule_stop_pairs, :active
  end
end
