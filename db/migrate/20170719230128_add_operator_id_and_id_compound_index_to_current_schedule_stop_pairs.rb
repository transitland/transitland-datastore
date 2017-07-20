class AddOperatorIdAndIdCompoundIndexToCurrentScheduleStopPairs < ActiveRecord::Migration
  def change
    add_index :current_schedule_stop_pairs, [:operator_id, :id] unless index_exists?(:current_schedule_stop_pairs, [:operator_id, :id])
    remove_index :current_schedule_stop_pairs, :operator_id
  end
end
